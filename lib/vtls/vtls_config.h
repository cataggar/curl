#ifndef HEADER_CURL_VTLS_CONFIG_H
#define HEADER_CURL_VTLS_CONFIG_H
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
#include "curl_setup.h"

struct Curl_easy;
struct connectdata;
struct Curl_peer;

struct ssl_filter_config {
  char *CApath;          /* certificate directory (does not work on Windows) */
  char *CAfile;          /* certificate to verify peer against */
  char *issuercert;      /* optional issuer certificate filename */
  char *clientcert;
  char *cipher_list;     /* list of ciphers to use */
  char *cipher_list13;   /* list of TLS 1.3 cipher suites to use */
  char *signature_algorithms; /* list of signature algorithms to use */
  char *pinned_key;
  char *CRLfile;         /* CRL to check certificate revocation */
  char *cert_type;       /* format for certificate (default: PEM) */
  char *key;             /* private key filename */
  char *key_type;        /* format for private key (default: PEM) */
  char *key_passwd;      /* plain text private key password */
#ifdef USE_ECH
  char *ech_config;      /* TLS ECH configuration, base64 string */
  char *ech_public;      /* TLS ECH public DNS (SNI in outer ClientHello) */
#endif
  struct curl_blob *cert_blob;
  struct curl_blob *ca_info_blob;
  struct curl_blob *issuercert_blob;
  struct curl_blob *key_blob;
  char *curves;          /* list of curves to use */
  uint32_t version_max; /* max supported version the client wants to use */
  uint8_t ssl_options;  /* the CURLOPT_SSL_OPTIONS bitmask */
  uint8_t version;    /* what version the client wants to use */
#ifdef USE_ECH
  uint8_t ech;           /* TLS ECH CURLECH_((DIS|EN)ABLE|GREASE) */
#endif
  BIT(verifypeer);       /* set TRUE if this is desired */
  BIT(verifyhost);       /* set TRUE if CN/SAN must match hostname */
  BIT(verifystatus);     /* set TRUE if certificate status must be checked */
  BIT(native_ca_store);  /* use the native CA store of operating system */
  BIT(cache_session);    /* cache session or not */
  BIT(deep_copy);        /* members are deep copies, eg. owned here */
  BIT(earlydata);        /* use TLS 1.3 early data */
  BIT(auto_client_cert);   /* automatically locate and use a client
                              certificate for authentication (Schannel) */
  BIT(enable_beast); /* allow this flaw for interoperability's sake */
  BIT(no_partialchain); /* do not accept partial certificate chains */
  BIT(no_revoke);    /* disable SSL certificate revocation checks */
  BIT(revoke_best_effort); /* ignore SSL revocation offline/missing revocation
                              list errors */
};

struct ssl_easy_config {
  long certverifyresult; /* result from the certificate verification */
  uint32_t version_max; /* max supported version the client wants to use */
  uint8_t version;    /* what version the client wants to use */
  uint8_t ssl_options;  /* the CURLOPT_SSL_OPTIONS bitmask */
#ifdef USE_ECH
  uint8_t ech;           /* TLS ECH CURLECH_((DIS|EN)ABLE|GREASE) */
#endif
  BIT(verifypeer);       /* set TRUE if this is desired */
  BIT(verifyhost);       /* set TRUE if CN/SAN must match hostname */
  BIT(verifystatus);     /* set TRUE if certificate status must be checked */
  BIT(cache_session);    /* cache session or not */
  BIT(certinfo);     /* gather lots of certificate info */
  BIT(custom_cafile); /* application has set custom CA file */
  BIT(custom_capath); /* application has set custom CA path */
  BIT(custom_cablob); /* application has set custom CA blob */
};

void Curl_ssl_config_init(struct ssl_easy_config *sslc);
void Curl_ssl_config_cleanup(struct ssl_filter_config *sslc);

#ifdef CURL_CA_PATH
#define CURL_ZIG_DEFAULT_CA_PATH CURL_CA_PATH
#else
#define CURL_ZIG_DEFAULT_CA_PATH NULL
#endif

#ifdef CURL_CA_BUNDLE
#define CURL_ZIG_DEFAULT_CA_BUNDLE CURL_CA_BUNDLE
#else
#define CURL_ZIG_DEFAULT_CA_BUNDLE NULL
#endif

#if defined(USE_APPLE_SECTRUST) || defined(CURL_CA_NATIVE)
#define CURL_ZIG_FORCE_NATIVE_CA TRUE
#else
#define CURL_ZIG_FORCE_NATIVE_CA FALSE
#endif

struct u8_strset;

/* Init the SSL filter configs *shallow* for connection matching
 * with origin and data's configuration settings. */
CURLcode Curl_ssl_filter_config_tmp_init_zig(
  struct Curl_easy *data,
  struct Curl_peer *origin,
  struct Curl_peer *initial_origin,
  struct ssl_easy_config *sslc,
  struct ssl_easy_config *proxy_sslc,
  struct u8_strset *strings,
  struct curl_blob **blobs,
  struct ssl_filter_config *ssl_origin,
  struct ssl_filter_config *ssl_proxy,
  const char *default_ca_path,
  const char *default_ca_bundle,
  bool force_native_ca,
  unsigned int str_ec_curves_id,
  unsigned int str_sig_algs_id);

#ifndef CURL_DISABLE_PROXY
#define Curl_ssl_filter_config_tmp_init(_vtls_data, _vtls_origin, \
                                        _vtls_ssl_origin, _vtls_ssl_proxy) \
  Curl_ssl_filter_config_tmp_init_zig( \
    (_vtls_data), (_vtls_origin), (_vtls_data)->state.initial_origin, \
    &(_vtls_data)->set.ssl, &(_vtls_data)->set.proxy_ssl, \
    &(_vtls_data)->set.strings, (_vtls_data)->set.blobs, \
    (_vtls_ssl_origin), (_vtls_ssl_proxy), \
    CURL_ZIG_DEFAULT_CA_PATH, CURL_ZIG_DEFAULT_CA_BUNDLE, \
    CURL_ZIG_FORCE_NATIVE_CA, \
    (unsigned int)STRING_SSL_EC_CURVES, \
    (unsigned int)STRING_SSL_SIGNATURE_ALGORITHMS)
#else
#define Curl_ssl_filter_config_tmp_init(_vtls_data, _vtls_origin, \
                                        _vtls_ssl_origin, _vtls_ssl_proxy) \
  Curl_ssl_filter_config_tmp_init_zig( \
    (_vtls_data), (_vtls_origin), (_vtls_data)->state.initial_origin, \
    &(_vtls_data)->set.ssl, NULL, \
    &(_vtls_data)->set.strings, (_vtls_data)->set.blobs, \
    (_vtls_ssl_origin), (_vtls_ssl_proxy), \
    CURL_ZIG_DEFAULT_CA_PATH, CURL_ZIG_DEFAULT_CA_BUNDLE, \
    CURL_ZIG_FORCE_NATIVE_CA, \
    (unsigned int)STRING_SSL_EC_CURVES, \
    (unsigned int)STRING_SSL_SIGNATURE_ALGORITHMS)
#endif

/* Clone the given filter configs into the connection. */
CURLcode Curl_ssl_conn_config_clone_zig(
  struct ssl_filter_config *ssl_config,
  struct ssl_filter_config *proxy_ssl_config,
  struct ssl_filter_config *conn_ssl_config,
  struct ssl_filter_config *conn_proxy_ssl_config);

#ifndef CURL_DISABLE_PROXY
#define Curl_ssl_conn_config_clone(_vtls_ssl_cfg, _vtls_proxy_ssl_cfg, \
                                   _vtls_conn) \
  Curl_ssl_conn_config_clone_zig((_vtls_ssl_cfg), (_vtls_proxy_ssl_cfg), \
    &(_vtls_conn)->ssl_config, &(_vtls_conn)->proxy_ssl_config)
#else
#define Curl_ssl_conn_config_clone(_vtls_ssl_cfg, _vtls_proxy_ssl_cfg, \
                                   _vtls_conn) \
  Curl_ssl_conn_config_clone_zig((_vtls_ssl_cfg), (_vtls_proxy_ssl_cfg), \
    &(_vtls_conn)->ssl_config, NULL)
#endif

/**
 * Free allocated resources in SSL configs (main + proxy) for
 * the given connection.
 */
void Curl_ssl_conn_config_cleanup_zig(
  struct ssl_filter_config *conn_ssl_config,
  struct ssl_filter_config *conn_proxy_ssl_config);

#ifndef CURL_DISABLE_PROXY
#define Curl_ssl_conn_config_cleanup(_vtls_conn) \
  Curl_ssl_conn_config_cleanup_zig(&(_vtls_conn)->ssl_config, \
    &(_vtls_conn)->proxy_ssl_config)
#else
#define Curl_ssl_conn_config_cleanup(_vtls_conn) \
  Curl_ssl_conn_config_cleanup_zig(&(_vtls_conn)->ssl_config, NULL)
#endif

/**
 * Return TRUE if `conn_config` is functionally the
 * same as the one on `candidate`.
 * @param proxy   match the proxy SSL config or the main one
 */
bool Curl_ssl_conn_config_match_zig(
  struct ssl_filter_config *conn_config,
  struct ssl_filter_config *cand_ssl_config,
  struct ssl_filter_config *cand_proxy_ssl_config,
  bool proxy);

#ifndef CURL_DISABLE_PROXY
#define Curl_ssl_conn_config_match(_vtls_data, _vtls_conn_cfg, \
                                   _vtls_cand, _vtls_proxy) \
  ((void)(_vtls_data), Curl_ssl_conn_config_match_zig((_vtls_conn_cfg), \
    &(_vtls_cand)->ssl_config, &(_vtls_cand)->proxy_ssl_config, \
    (_vtls_proxy)))
#else
#define Curl_ssl_conn_config_match(_vtls_data, _vtls_conn_cfg, \
                                   _vtls_cand, _vtls_proxy) \
  ((void)(_vtls_data), Curl_ssl_conn_config_match_zig((_vtls_conn_cfg), \
    &(_vtls_cand)->ssl_config, NULL, (_vtls_proxy)))
#endif

/* Update certain connection SSL config flags after they have
 * been changed on the easy handle. Works for `verifypeer`,
 * `verifyhost` and `verifystatus`. */
void Curl_ssl_conn_config_update_zig(struct ssl_easy_config *src,
                                     struct ssl_filter_config *dest);

#ifndef CURL_DISABLE_PROXY
#define Curl_ssl_conn_config_update(_vtls_data, _vtls_for_proxy) \
  Curl_ssl_conn_config_update_zig( \
    (_vtls_for_proxy) ? &(_vtls_data)->set.proxy_ssl : &(_vtls_data)->set.ssl, \
    (_vtls_data)->conn ? ((_vtls_for_proxy) ? \
      &(_vtls_data)->conn->proxy_ssl_config : \
      &(_vtls_data)->conn->ssl_config) : NULL)
#else
#define Curl_ssl_conn_config_update(_vtls_data, _vtls_for_proxy) \
  ((void)(_vtls_for_proxy), Curl_ssl_conn_config_update_zig( \
    &(_vtls_data)->set.ssl, \
    (_vtls_data)->conn ? &(_vtls_data)->conn->ssl_config : NULL))
#endif

#endif /* HEADER_CURL_VTLS_CONFIG_H */
