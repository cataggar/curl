/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at https://curl.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 * SPDX-License-Identifier: curl
 *
 ***************************************************************************/
#include "tool_setup.h"

#ifdef _WIN32
#include <tchar.h>
#endif

#include <signal.h>

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include "tool_cfgable.h"
#include "tool_doswin.h"
#include "tool_msgs.h"
#include "tool_operate.h"
#include "tool_vms.h"
#include "tool_main.h"
#include "tool_stderr.h"

#ifdef __VMS
/*
 * vms_show is a global variable, used in main() as parameter for
 * function vms_special_exit() to allow proper curl tool exiting.
 * Its value may be set in other tool_*.c source files thanks to
 * forward declaration present in tool_vms.h
 */
int vms_show = 0;
#endif

#ifdef __AMIGA__
#ifdef __GNUC__
#define CURL_USED __attribute__((used))
#else
#define CURL_USED
#endif
static const char CURL_USED min_stack[] = "$STACK:32768";
#endif

#ifdef __MINGW32__
/*
 * There seems to be no way to escape "*" in command-line arguments with MinGW
 * when command-line argument globbing is enabled under the MSYS shell, so turn
 * it off.
 */
extern int _CRT_glob;
int _CRT_glob = 0;
#endif /* __MINGW32__ */

/* if we build a static library for unit tests, there is no main() function */
#ifndef UNITTESTS

/*
 * Ensure that file descriptors 0, 1 and 2 (stdin, stdout, stderr) are
 * open before starting to run. Otherwise, the first three network
 * sockets opened by curl could be used for input sources, downloaded data
 * or error logs as they are effectively stdin, stdout and/or stderr.
 *
 * fcntl's F_GETFD instruction returns -1 if the file descriptor is closed,
 * otherwise it returns "the file descriptor flags (which typically can only
 * be FD_CLOEXEC, which is not set here).
 */
static int main_checkfds(void)
{
#if defined(HAVE_FCNTL) && defined(HAVE_PIPE)
  const char * const devnull = "/dev/null";
  int fd;
  while((fcntl(STDIN_FILENO, F_GETFD) == -1)) {
    fd = curlx_open(devnull, O_RDONLY);
    if(fd < 0)
      return 1;
  }
  while((fcntl(STDOUT_FILENO, F_GETFD) == -1)) {
    fd = curlx_open(devnull, O_WRONLY);
    if(fd < 0)
      return 1;
  }
  while((fcntl(STDERR_FILENO, F_GETFD) == -1)) {
    fd = curlx_open(devnull, O_WRONLY);
    if(fd < 0)
      return 1;
  }
#endif /* HAVE_FCNTL && HAVE_PIPE */
  return 0;
}

#ifdef CURL_MEMDEBUG
static void memory_tracking_init(void)
{
  char *env;
  /* if CURL_MEMDEBUG is set, this starts memory tracking message logging */
  env = curl_getenv("CURL_MEMDEBUG");
  if(env) {
    /* use the value as filename */
    char fname[512];
    curlx_strcopy(fname, sizeof(fname), env, strlen(env));
    curl_free(env);
    curl_dbg_memdebug(fname);
    /* this weird stuff here is to make curl_free() get called before
       curl_dbg_memdebug() as otherwise memory tracking logs a curlx_free()
       without an alloc! */
  }
  /* if CURL_MEMLIMIT is set, this enables fail-on-alloc-number-N feature */
  env = curl_getenv("CURL_MEMLIMIT");
  if(env) {
    curl_off_t num;
    const char *p = env;
    if(!curlx_str_number(&p, &num, LONG_MAX))
      curl_dbg_memlimit((long)num);
    curl_free(env);
  }
}
#else
#  define memory_tracking_init() tool_nop_stmt
#endif

/*
 * curl tool main function.
 */
#ifdef _UNICODE
#ifdef CURL_HAVE_DIAG
/* GCC does not know about wmain() */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-prototypes"
#pragma GCC diagnostic ignored "-Wmissing-declarations"
#endif
int wmain(int argc, wchar_t *argv[])
#else
int main(int argc, char *argv[])
#endif
{
  CURLcode result = CURLE_OK;

  CURL_MSVC_CRTDBG_INIT();

  tool_init_stderr();

#ifdef _WIN32
  /* Undocumented diagnostic option to list the full paths of all loaded
     modules. This is purposely pre-init. */
  if(argc == 2 && !_tcscmp(argv[1], _TEXT("--dump-module-paths"))) {
    CURL_DUMP_MODULE_PATHS(curl_mprintf);
    return 0;
  }

  /* win32_init must be called before other init routines. */
  result = win32_init();
  if(result) {
    errorf("(%d) Windows-specific init failed", (int)result);
    return (int)result;
  }
#endif

  if(main_checkfds()) {
    errorf("out of file descriptors");
    return CURLE_FAILED_INIT;
  }

#if defined(HAVE_SIGNAL) && defined(SIGPIPE)
#ifdef DEBUGBUILD
  if(!curl_getenv("CURL_SIGPIPE_DEBUG"))
#endif
  (void)signal(SIGPIPE, SIG_IGN);
#endif

  /* Initialize memory tracking */
  memory_tracking_init();

  /* Initialize the curl library - do not call any libcurl functions before
     this point */
  result = globalconf_init();
  if(!result) {
    /* Start our curl operation */
    result = operate(argc, argv);

    /* Perform the main cleanup */
    globalconf_free();
  }

#ifdef _WIN32
  /* Flush buffers of all streams opened in write or update mode */
  fflush(NULL);
#endif

#ifdef __VMS
  vms_special_exit(result, vms_show);
#else
  return (int)result;
#endif
}

#ifdef _UNICODE
#ifdef CURL_HAVE_DIAG
#pragma GCC diagnostic pop
#endif
#endif

#endif /* !UNITTESTS */

#ifdef HAVE_PWD_H
#include <pwd.h>
#endif

struct tool_var *tool_zig_get_variables(void)
{
  return global->variables;
}

void tool_zig_set_variables(struct tool_var *v)
{
  global->variables = v;
}

struct OperationConfig *tool_zig_get_global_last(void)
{
  return global->last;
}

bool tool_zig_next_operation(struct OperationConfig **configp)
{
  struct OperationConfig *config = *configp;
  if(config->url_list && config->url_list->url) {
    config->next = config_alloc();
    if(config->next) {
      global->last = config->next;
      config->next->prev = config;
      *configp = config->next;
    }
    else
      return FALSE;
  }
  return TRUE;
}

FILE *tool_zig_stdin(void)
{
  return stdin;
}

int tool_zig_get_errno(void)
{
  return errno;
}

bool tool_zig_errno_is_acces_or_exist(void)
{
  return (errno == EACCES) || (errno == EEXIST);
}

void tool_zig_show_dir_errno(const char *name)
{
  switch(errno) {
#ifdef EACCES
  case EACCES:
    errorf("You do not have permission to create %s", name);
    break;
#endif
#ifdef ENAMETOOLONG
  case ENAMETOOLONG:
    errorf("The directory name %s is too long", name);
    break;
#endif
#ifdef EROFS
  case EROFS:
    errorf("%s resides on a read-only file system", name);
    break;
#endif
#ifdef ENOSPC
  case ENOSPC:
    errorf("No space left on the file system that would "
           "contain the directory %s", name);
    break;
#endif
#ifdef EDQUOT
  case EDQUOT:
    errorf("Cannot create directory %s because you "
           "exceeded your quota", name);
    break;
#endif
  default:
    errorf("Error creating directory %s", name);
    break;
  }
}

#ifndef _WIN32
int tool_zig_stat_mtime(const char *filename, curl_off_t *stamp)
{
  curlx_struct_stat statbuf;
  if(curlx_stat(filename, &statbuf) != -1) {
    *stamp = (curl_off_t)statbuf.st_mtime;
    return 0;
  }
  return -1;
}
#else
void tool_zig_set_config_cacert(struct OperationConfig *config, char *cacert)
{
  curlx_free(config->cacert);
  config->cacert = cacert;
}
#endif

const char *tool_zig_get_pw_dir(void)
{
#if defined(HAVE_GETPWUID) && defined(HAVE_GETEUID)
  struct passwd *pw = getpwuid(geteuid());
  if(pw && pw->pw_dir && pw->pw_dir[0])
    return pw->pw_dir;
#endif
  return NULL;
}

void tool_zig_errorf_0(const char *msg)
{
  errorf("%s", msg);
}

void tool_zig_errorf_s(const char *fmt, const char *s)
{
  errorf(fmt, s);
}

void tool_zig_errorf_ss(const char *fmt, const char *s1, const char *s2)
{
  errorf(fmt, s1, s2);
}

void tool_zig_errorf_ns(const char *fmt, int n, const char *s)
{
  errorf(fmt, n, s);
}

void tool_zig_errorf_d(const char *fmt, int d)
{
  errorf(fmt, d);
}

void tool_zig_errorf_lx(const char *fmt, unsigned long lx)
{
  errorf(fmt, lx);
}

void tool_zig_errorf_cfg(const char *display, int lineno, const char *option,
                         const char *reason)
{
  errorf("%s:%d config file option '%s' %s", display, lineno, option, reason);
}

void tool_zig_warnf_0(const char *msg)
{
  warnf("%s", msg);
}

void tool_zig_warnf_s(const char *fmt, const char *s)
{
  warnf(fmt, s);
}

void tool_zig_warnf_zu(const char *fmt, size_t n)
{
  warnf(fmt, n);
}

void tool_zig_warnf_lx(const char *fmt, unsigned long lx)
{
  warnf(fmt, lx);
}

void tool_zig_warnf_off_lx(const char *fmt, curl_off_t off, unsigned long lx)
{
  warnf(fmt, off, lx);
}

void tool_zig_warnf_off_ss(const char *fmt, curl_off_t off, const char *s1,
                           const char *s2)
{
  warnf(fmt, off, s1, s2);
}

void tool_zig_warnf_cfg(const char *fmt, const char *filename, int lineno,
                        const char *option)
{
  warnf(fmt, filename, lineno, option);
}

void tool_zig_notef_s(const char *fmt, const char *s)
{
  notef(fmt, s);
}

#include "tool_libinfo.h"

bool tool_zig_has_ares(void)
{
  return curlinfo && curlinfo->ares_num != 0;
}

bool tool_zig_existingfile(const char *filename)
{
  curlx_struct_stat info;
  return curlx_stat(filename, &info) == 0;
}

void tool_zig_stdin_binmode(void)
{
  CURL_BINMODE(stdin);
}

char **tool_zig_config_str_ptr(struct OperationConfig *config, int id)
{
  switch(id) {
  case 0: return &config->altsvc;
  case 1: return &config->aws_sigv4;
  case 2: return &config->cacert;
  case 3: return &config->capath;
  case 4: return &config->cert;
  case 5: return &config->cert_type;
  case 6: return &config->cipher13_list;
  case 7: return &config->cipher_list;
  case 8: return &config->cookiejar;
  case 9: return &config->crlfile;
  case 10: return &config->customrequest;
  case 11: return &config->dns_interface;
  case 12: return &config->dns_ipv4_addr;
  case 13: return &config->dns_ipv6_addr;
  case 14: return &config->dns_servers;
  case 15: return &config->doh_url;
  case 16: return &config->ech;
  case 17: return &config->ech_config;
  case 18: return &config->ech_public;
  case 19: return &config->engine;
  case 20: return &config->etag_compare_file;
  case 21: return &config->etag_save_file;
  case 22: return &config->ftp_account;
  case 23: return &config->ftp_alternative_to_user;
  case 24: return &config->ftpport;
  case 25: return &config->haproxy_clientip;
  case 26: return &config->headerfile;
  case 27: return &config->hostpubmd5;
  case 28: return &config->hostpubsha256;
  case 29: return &config->hsts;
  case 30: return &config->httpsig_algorithm;
  case 31: return &config->httpsig_headers;
  case 32: return &config->httpsig_key;
  case 33: return &config->httpsig_keyid;
  case 34: return &config->iface;
  case 35: return &config->ipfs_gateway;
  case 36: return &config->key;
  case 37: return &config->key_passwd;
  case 38: return &config->key_type;
  case 39: return &config->knownhosts;
  case 40: return &config->login_options;
  case 41: return &config->mail_auth;
  case 42: return &config->mail_from;
  case 43: return &config->netrc_file;
  case 44: return &config->noproxy;
  case 45: return &config->oauth_bearer;
  case 46: return &config->output_dir;
  case 47: return &config->pinnedpubkey;
  case 48: return &config->postfields;
  case 49: return &config->preproxy;
  case 50: return &config->proto_default;
  case 51: return &config->proto_redir_str;
  case 52: return &config->proto_str;
  case 53: return &config->proxy;
  case 54: return &config->proxy_cacert;
  case 55: return &config->proxy_capath;
  case 56: return &config->proxy_cert;
  case 57: return &config->proxy_cert_type;
  case 58: return &config->proxy_cipher13_list;
  case 59: return &config->proxy_cipher_list;
  case 60: return &config->proxy_crlfile;
  case 61: return &config->proxy_key;
  case 62: return &config->proxy_key_passwd;
  case 63: return &config->proxy_key_type;
  case 64: return &config->proxy_pinnedpubkey;
  case 65: return &config->proxy_service_name;
  case 66: return &config->proxyuserpwd;
  case 67: return &config->pubkey;
  case 68: return &config->query;
  case 69: return &config->range;
  case 70: return &config->referer;
  case 71: return &config->request_target;
  case 72: return &config->sasl_authzid;
  case 73: return &config->service_name;
  case 74: return &config->ssl_ec_curves;
  case 75: return &config->ssl_signature_algorithms;
  case 76: return &config->unix_socket_path;
  case 77: return &config->useragent;
  case 78: return &config->userpwd;
  case 79: return &config->writeout;
  default: return NULL;
  }
}

struct curl_slist **tool_zig_config_slist_ptr(struct OperationConfig *config, int id)
{
  switch(id) {
  case 0: return &config->connect_to;
  case 1: return &config->cookiefiles;
  case 2: return &config->cookies;
  case 3: return &config->headers;
  case 4: return &config->mail_rcpt;
  case 5: return &config->postquote;
  case 6: return &config->prequote;
  case 7: return &config->proxyheaders;
  case 8: return &config->quote;
  case 9: return &config->resolve;
  case 10: return &config->telnet_options;
  default: return NULL;
  }
}

bool tool_zig_config_get_bit(const struct OperationConfig *config, int id)
{
  switch(id) {
  case 0: return config->abstract_unix_socket != 0;
  case 1: return config->autoreferer != 0;
  case 2: return config->content_disposition != 0;
  case 3: return config->cookiesession != 0;
  case 4: return config->create_dirs != 0;
  case 5: return config->crlf != 0;
  case 6: return config->dirlistonly != 0;
  case 7: return config->disable_eprt != 0;
  case 8: return config->disable_epsv != 0;
  case 9: return config->disable_sessionid != 0;
  case 10: return config->disallow_username_in_url != 0;
  case 11: return config->doh_insecure_ok != 0;
  case 12: return config->doh_verifystatus != 0;
  case 13: return config->encoding != 0;
  case 14: return config->ftp_append != 0;
  case 15: return config->ftp_create_dirs != 0;
  case 16: return config->ftp_pret != 0;
  case 17: return config->ftp_skip_ip != 0;
  case 18: return config->ftp_ssl != 0;
  case 19: return config->ftp_ssl_ccc != 0;
  case 20: return config->ftp_ssl_control != 0;
  case 21: return config->ftp_ssl_reqd != 0;
  case 22: return config->globoff != 0;
  case 23: return config->haproxy_protocol != 0;
  case 24: return config->http09_allowed != 0;
  case 25: return config->ignorecl != 0;
  case 26: return config->insecure_ok != 0;
  case 27: return config->jsoned != 0;
  case 28: return config->mail_rcpt_allowfails != 0;
  case 29: return config->mptcp != 0;
  case 30: return config->native_ca_store != 0;
  case 31: return config->netrc != 0;
  case 32: return config->netrc_opt != 0;
  case 33: return config->no_body != 0;
  case 34: return config->noalpn != 0;
  case 35: return config->nobuffer != 0;
  case 36: return config->nokeepalive != 0;
  case 37: return config->path_as_is != 0;
  case 38: return config->post301 != 0;
  case 39: return config->post302 != 0;
  case 40: return config->post303 != 0;
  case 41: return config->proto_present != 0;
  case 42: return config->proto_redir_present != 0;
  case 43: return config->proxy_insecure_ok != 0;
  case 44: return config->proxy_native_ca_store != 0;
  case 45: return config->proxy_ssl_allow_beast != 0;
  case 46: return config->proxy_ssl_auto_client_cert != 0;
  case 47: return config->proxyanyauth != 0;
  case 48: return config->proxybasic != 0;
  case 49: return config->proxydigest != 0;
  case 50: return config->proxynegotiate != 0;
  case 51: return config->proxyntlm != 0;
  case 52: return config->proxytunnel != 0;
  case 53: return config->raw != 0;
  case 54: return config->remote_name_all != 0;
  case 55: return config->remote_time != 0;
  case 56: return config->resume_from_current != 0;
  case 57: return config->retry_all_errors != 0;
  case 58: return config->retry_connrefused != 0;
  case 59: return config->rm_partial != 0;
  case 60: return config->sasl_ir != 0;
  case 61: return config->show_headers != 0;
  case 62: return config->skip_existing != 0;
  case 63: return config->socks5_gssapi_nec != 0;
  case 64: return config->ssh_compression != 0;
  case 65: return config->ssl_allow_beast != 0;
  case 66: return config->ssl_allow_earlydata != 0;
  case 67: return config->ssl_auto_client_cert != 0;
  case 68: return config->ssl_no_revoke != 0;
  case 69: return config->ssl_revoke_best_effort != 0;
  case 70: return config->suppress_connect_headers != 0;
  case 71: return config->tcp_fastopen != 0;
  case 72: return config->tcp_nodelay != 0;
  case 73: return config->tftp_no_options != 0;
  case 74: return config->tr_encoding != 0;
  case 75: return config->unrestricted_auth != 0;
  case 76: return config->use_ascii != 0;
  case 77: return config->use_httpget != 0;
  case 78: return config->use_resume != 0;
  case 79: return config->verifystatus != 0;
  case 80: return config->xattr != 0;
  default: return FALSE;
  }
}

void tool_zig_config_set_bit(struct OperationConfig *config, int id, bool val)
{
  switch(id) {
  case 0: config->abstract_unix_socket = val; break;
  case 1: config->autoreferer = val; break;
  case 2: config->content_disposition = val; break;
  case 3: config->cookiesession = val; break;
  case 4: config->create_dirs = val; break;
  case 5: config->crlf = val; break;
  case 6: config->dirlistonly = val; break;
  case 7: config->disable_eprt = val; break;
  case 8: config->disable_epsv = val; break;
  case 9: config->disable_sessionid = val; break;
  case 10: config->disallow_username_in_url = val; break;
  case 11: config->doh_insecure_ok = val; break;
  case 12: config->doh_verifystatus = val; break;
  case 13: config->encoding = val; break;
  case 14: config->ftp_append = val; break;
  case 15: config->ftp_create_dirs = val; break;
  case 16: config->ftp_pret = val; break;
  case 17: config->ftp_skip_ip = val; break;
  case 18: config->ftp_ssl = val; break;
  case 19: config->ftp_ssl_ccc = val; break;
  case 20: config->ftp_ssl_control = val; break;
  case 21: config->ftp_ssl_reqd = val; break;
  case 22: config->globoff = val; break;
  case 23: config->haproxy_protocol = val; break;
  case 24: config->http09_allowed = val; break;
  case 25: config->ignorecl = val; break;
  case 26: config->insecure_ok = val; break;
  case 27: config->jsoned = val; break;
  case 28: config->mail_rcpt_allowfails = val; break;
  case 29: config->mptcp = val; break;
  case 30: config->native_ca_store = val; break;
  case 31: config->netrc = val; break;
  case 32: config->netrc_opt = val; break;
  case 33: config->no_body = val; break;
  case 34: config->noalpn = val; break;
  case 35: config->nobuffer = val; break;
  case 36: config->nokeepalive = val; break;
  case 37: config->path_as_is = val; break;
  case 38: config->post301 = val; break;
  case 39: config->post302 = val; break;
  case 40: config->post303 = val; break;
  case 41: config->proto_present = val; break;
  case 42: config->proto_redir_present = val; break;
  case 43: config->proxy_insecure_ok = val; break;
  case 44: config->proxy_native_ca_store = val; break;
  case 45: config->proxy_ssl_allow_beast = val; break;
  case 46: config->proxy_ssl_auto_client_cert = val; break;
  case 47: config->proxyanyauth = val; break;
  case 48: config->proxybasic = val; break;
  case 49: config->proxydigest = val; break;
  case 50: config->proxynegotiate = val; break;
  case 51: config->proxyntlm = val; break;
  case 52: config->proxytunnel = val; break;
  case 53: config->raw = val; break;
  case 54: config->remote_name_all = val; break;
  case 55: config->remote_time = val; break;
  case 56: config->resume_from_current = val; break;
  case 57: config->retry_all_errors = val; break;
  case 58: config->retry_connrefused = val; break;
  case 59: config->rm_partial = val; break;
  case 60: config->sasl_ir = val; break;
  case 61: config->show_headers = val; break;
  case 62: config->skip_existing = val; break;
  case 63: config->socks5_gssapi_nec = val; break;
  case 64: config->ssh_compression = val; break;
  case 65: config->ssl_allow_beast = val; break;
  case 66: config->ssl_allow_earlydata = val; break;
  case 67: config->ssl_auto_client_cert = val; break;
  case 68: config->ssl_no_revoke = val; break;
  case 69: config->ssl_revoke_best_effort = val; break;
  case 70: config->suppress_connect_headers = val; break;
  case 71: config->tcp_fastopen = val; break;
  case 72: config->tcp_nodelay = val; break;
  case 73: config->tftp_no_options = val; break;
  case 74: config->tr_encoding = val; break;
  case 75: config->unrestricted_auth = val; break;
  case 76: config->use_ascii = val; break;
  case 77: config->use_httpget = val; break;
  case 78: config->use_resume = val; break;
  case 79: config->verifystatus = val; break;
  case 80: config->xattr = val; break;
  default: break;
  }
}

curl_off_t tool_zig_config_get_int(const struct OperationConfig *config, int id)
{
  switch(id) {
  case 0: return (curl_off_t)config->alivecnt;
  case 1: return (curl_off_t)config->alivetime;
  case 2: return (curl_off_t)config->authtype;
  case 3: return (curl_off_t)config->condtime;
  case 4: return (curl_off_t)config->connecttimeout_ms;
  case 5: return (curl_off_t)config->create_file_mode;
  case 6: return (curl_off_t)config->expect100timeout_ms;
  case 7: return (curl_off_t)config->fail;
  case 8: return (curl_off_t)config->file_clobber_mode;
  case 9: return (curl_off_t)config->followlocation;
  case 10: return (curl_off_t)config->ftp_filemethod;
  case 11: return (curl_off_t)config->ftp_ssl_ccc_mode;
  case 12: return (curl_off_t)config->gssapi_delegation;
  case 13: return (curl_off_t)config->happy_eyeballs_timeout_ms;
  case 14: return (curl_off_t)config->httpreq;
  case 15: return (curl_off_t)config->httpversion;
  case 16: return (curl_off_t)config->ip_tos;
  case 17: return (curl_off_t)config->ip_version;
  case 18: return (curl_off_t)config->localport;
  case 19: return (curl_off_t)config->localportrange;
  case 20: return (curl_off_t)config->low_speed_limit;
  case 21: return (curl_off_t)config->low_speed_time;
  case 22: return (curl_off_t)config->max_filesize;
  case 23: return (curl_off_t)config->maxredirs;
  case 24: return (curl_off_t)config->mime_options;
  case 25: return (curl_off_t)config->num_urls;
  case 26: return (curl_off_t)config->proxy_ssl_version;
  case 27: return (curl_off_t)config->proxyver;
  case 28: return (curl_off_t)config->recvpersecond;
  case 29: return (curl_off_t)config->req_retry;
  case 30: return (curl_off_t)config->resume_from;
  case 31: return (curl_off_t)config->retry_delay_ms;
  case 32: return (curl_off_t)config->retry_maxtime_ms;
  case 33: return (curl_off_t)config->sendpersecond;
  case 34: return (curl_off_t)config->socks5_auth;
  case 35: return (curl_off_t)config->ssl_version;
  case 36: return (curl_off_t)config->ssl_version_max;
  case 37: return (curl_off_t)config->tftp_blksize;
  case 38: return (curl_off_t)config->timecond;
  case 39: return (curl_off_t)config->timeout_ms;
  case 40: return (curl_off_t)config->upload_flags;
  case 41: return (curl_off_t)config->vlan_priority;
  default: return 0;
  }
}

void tool_zig_config_set_int(struct OperationConfig *config, int id, curl_off_t val)
{
  switch(id) {
  case 0: config->alivecnt = (long)val; break;
  case 1: config->alivetime = (long)val; break;
  case 2: config->authtype = (unsigned long)val; break;
  case 3: config->condtime = (curl_off_t)val; break;
  case 4: config->connecttimeout_ms = (long)val; break;
  case 5: config->create_file_mode = (long)val; break;
  case 6: config->expect100timeout_ms = (long)val; break;
  case 7: config->fail = (unsigned char)val; break;
  case 8: config->file_clobber_mode = (int)val; break;
  case 9: config->followlocation = (long)val; break;
  case 10: config->ftp_filemethod = (long)val; break;
  case 11: config->ftp_ssl_ccc_mode = (long)val; break;
  case 12: config->gssapi_delegation = (long)val; break;
  case 13: config->happy_eyeballs_timeout_ms = (long)val; break;
  case 14: config->httpreq = (HttpReq)val; break;
  case 15: config->httpversion = (long)val; break;
  case 16: config->ip_tos = (long)val; break;
  case 17: config->ip_version = (long)val; break;
  case 18: config->localport = (long)val; break;
  case 19: config->localportrange = (long)val; break;
  case 20: config->low_speed_limit = (long)val; break;
  case 21: config->low_speed_time = (long)val; break;
  case 22: config->max_filesize = (curl_off_t)val; break;
  case 23: config->maxredirs = (long)val; break;
  case 24: config->mime_options = (unsigned long)val; break;
  case 25: config->num_urls = (size_t)val; break;
  case 26: config->proxy_ssl_version = (long)val; break;
  case 27: config->proxyver = (long)val; break;
  case 28: config->recvpersecond = (curl_off_t)val; break;
  case 29: config->req_retry = (long)val; break;
  case 30: config->resume_from = (curl_off_t)val; break;
  case 31: config->retry_delay_ms = (uint32_t)val; break;
  case 32: config->retry_maxtime_ms = (long)val; break;
  case 33: config->sendpersecond = (curl_off_t)val; break;
  case 34: config->socks5_auth = (unsigned long)val; break;
  case 35: config->ssl_version = (unsigned char)val; break;
  case 36: config->ssl_version_max = (unsigned char)val; break;
  case 37: config->tftp_blksize = (long)val; break;
  case 38: config->timecond = (unsigned long)val; break;
  case 39: config->timeout_ms = (long)val; break;
  case 40: config->upload_flags = (unsigned char)val; break;
  case 41: config->vlan_priority = (long)val; break;
  default: break;
  }
}

struct getout **tool_zig_config_getout_ptr(struct OperationConfig *config, int id)
{
  switch(id) {
  case 0: return &config->url_get;
  case 1: return &config->url_list;
  case 2: return &config->url_out;
  case 3: return &config->url_ul;
  default: return NULL;
  }
}

struct tool_mime **tool_zig_config_mimeroot_ptr(struct OperationConfig *config)
{
  return &config->mimeroot;
}

struct tool_mime **tool_zig_config_mimecurrent_ptr(struct OperationConfig *config)
{
  return &config->mimecurrent;
}

struct dynbuf *tool_zig_config_postdata_ptr(struct OperationConfig *config)
{
  return &config->postdata;
}

struct OperationConfig *tool_zig_config_alloc_next(struct OperationConfig *config)
{
  config->next = config_alloc();
  if(!config->next)
    return NULL;
  config->next->prev = config;
  global->last = config->next;
  return config->next;
}

struct OperationConfig *tool_zig_global_first(void)
{
  return global ? global->first : NULL;
}

char **tool_zig_global_str_ptr(int id)
{
  switch(id) {
  case 0: return &global->libcurl;
  case 1: return &global->ssl_sessions;
  case 2: return &global->trace_dump;
  default: return NULL;
  }
}

bool tool_zig_global_get_bit(int id)
{
  switch(id) {
  case 0: return global->fail_early != 0;
  case 1: return global->noprogress != 0;
  case 2: return global->parallel != 0;
  case 3: return global->parallel_connect != 0;
  case 4: return global->showerror != 0;
  case 5: return global->silent != 0;
  case 6: return global->styled_output != 0;
  case 7: return global->trace_set != 0;
  case 8: return global->traceids != 0;
  case 9: return global->tracetime != 0;
  default: return FALSE;
  }
}

void tool_zig_global_set_bit(int id, bool val)
{
  switch(id) {
  case 0: global->fail_early = val; break;
  case 1: global->noprogress = val; break;
  case 2: global->parallel = val; break;
  case 3: global->parallel_connect = val; break;
  case 4: global->showerror = val; break;
  case 5: global->silent = val; break;
  case 6: global->styled_output = val; break;
  case 7: global->trace_set = val; break;
  case 8: global->traceids = val; break;
  case 9: global->tracetime = val; break;
  default: break;
  }
}

curl_off_t tool_zig_global_get_int(int id)
{
  switch(id) {
  case 0: return (curl_off_t)global->ms_per_transfer;
  case 1: return (curl_off_t)global->parallel_host;
  case 2: return (curl_off_t)global->parallel_max;
  case 3: return (curl_off_t)global->progressmode;
  case 4: return (curl_off_t)global->tracetype;
  case 5: return (curl_off_t)global->verbosity;
  default: return 0;
  }
}

void tool_zig_global_set_int(int id, curl_off_t val)
{
  switch(id) {
  case 0: global->ms_per_transfer = (timediff_t)val; break;
  case 1: global->parallel_host = (unsigned short)val; break;
  case 2: global->parallel_max = (unsigned short)val; break;
  case 3: global->progressmode = (int)val; break;
  case 4: global->tracetype = (trace)val; break;
  case 5: global->verbosity = (unsigned char)val; break;
  default: break;
  }
}

char **tool_zig_getout_str_ptr(struct getout *node, int id)
{
  switch(id) {
  case 0: return &node->infile;
  case 1: return &node->outfile;
  case 2: return &node->url;
  default: return NULL;
  }
}

bool tool_zig_getout_get_bit(const struct getout *node, int id)
{
  switch(id) {
  case 0: return node->noglob != 0;
  case 1: return node->noupload != 0;
  case 2: return node->out_null != 0;
  case 3: return node->outset != 0;
  case 4: return node->uploadset != 0;
  case 5: return node->urlset != 0;
  case 6: return node->useremote != 0;
  default: return FALSE;
  }
}

void tool_zig_getout_set_bit(struct getout *node, int id, bool val)
{
  switch(id) {
  case 0: node->noglob = val; break;
  case 1: node->noupload = val; break;
  case 2: node->out_null = val; break;
  case 3: node->outset = val; break;
  case 4: node->uploadset = val; break;
  case 5: node->urlset = val; break;
  case 6: node->useremote = val; break;
  default: break;
  }
}

struct getout *tool_zig_getout_next(const struct getout *node)
{
  return node->next;
}
