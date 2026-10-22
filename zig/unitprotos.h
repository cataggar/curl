#ifndef UNITTESTPROTOS_H
#define UNITTESTPROTOS_H
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
 * Generated-by: extract-unit-protos
 *
 ***************************************************************************/
#include "cf-ip-happy.h"
#include "cf-socket.h"
#include "connect.h"
#include "dynhds.h"
#include "ftp.h"
#include "hash.h"
#include "hsts.h"
#include "http_aws_sigv4.h"
#include "llist.h"
#include "parsedate.h"
#include "progress.h"
#include "proxy.h"
#include "splay.h"
#include "thrdqueue.h"
#include "u8_strset.h"
#include "uint-bset.h"
#include "uint-spbset.h"
#include "uint-table.h"
#include "vdns/dnscache.h"
#include "vdns/doh.h"
#include "vquic/capsule.h"
#include "vtls/x509asn1.h"

/* for unit test 2600 from cf-ip-happy.c:105 */
UNITTEST void debug_set_transport_provider(
  uint8_t transport, cf_ip_connect_create *cf_create);

/* for unit test 1607 from cf-socket.c:94 */
UNITTEST CURLcode sockaddr2string(struct sockaddr *sa, curl_socklen_t salen,
                                  char *addr, uint16_t *port);

/* for unit test 1303 from connect.c:68 */
UNITTEST timediff_t timeleft_now_ms(struct Curl_easy *data,
                                    const struct curltime *pnow);

/* for unit test 2602 from dynhds.c:239 */
UNITTEST bool dynhds_contains(struct dynhds *dynhds,
                              const char *name, size_t namelen);

/* for unit test 2602 from dynhds.c:248 */
UNITTEST bool dynhds_ccontains(struct dynhds *dynhds, const char *name);

/* for unit test 2602 from dynhds.c:260 */
UNITTEST size_t dynhds_count_name(struct dynhds *dynhds,
                                  const char *name, size_t namelen);

/* for unit test 2602 from dynhds.c:283 */
UNITTEST size_t dynhds_ccount_name(struct dynhds *dynhds,
                                        const char *name);

/* for unit test 2602 from dynhds.c:297 */
UNITTEST size_t dynhds_remove(struct dynhds *dynhds,
                              const char *name, size_t namelen);

/* for unit test 2602 from dynhds.c:332 */
UNITTEST CURLcode dynhds_set(struct dynhds *dynhds,
                             const char *name, size_t namelen,
                             const char *value, size_t valuelen);

/* for unit test 2602 from dynhds.c:344 */
UNITTEST size_t dynhds_cremove(struct dynhds *dynhds, const char *name);

/* for unit test 1668 from ftp.c:2455 */
UNITTEST bool ftp_213_date(const char *p, int *year, int *month, int *day,
                           int *hour, int *minute, int *second);

/* for unit test 1603 from hash.c:88 */
UNITTEST size_t hash_str_seeded(const void *key, size_t key_length,
                                size_t slots_num, size_t seed);

/* for unit test 1603 from hash.c:108 */
UNITTEST size_t hash_str(const void *key, size_t key_length, size_t slots_num);

/* for unit test 1660 from hsts.c:163 */
UNITTEST struct stsentry *hsts_check(struct hsts *h, const char *hostname,
                                     size_t hlen, bool subdomain);

/* for unit test 1979 from http_aws_sigv4.c:671 */
UNITTEST CURLcode canon_path(const char *q, size_t len,
                             struct dynbuf *new_path,
                             bool do_uri_encode);

/* for unit test 1980 from http_aws_sigv4.c:699 */
UNITTEST CURLcode canon_query(const char *query, struct dynbuf *dq);

/* for unit test 1300 from llist.c:67 */
UNITTEST void llist_insert_next(struct Curl_llist *list,
                                struct Curl_llist_node *e, const void *p,
                                struct Curl_llist_node *ne);

/* for unit test 1300 from llist.c:218 */
UNITTEST struct Curl_llist_node *llist_tail(const struct Curl_llist *list);

/* for unit test 1300 from llist.c:257 */
UNITTEST struct Curl_llist_node *llist_node_prev(
  const struct Curl_llist_node *n);

/* for unit test 4781 from parsedate.c:211 */
UNITTEST int checkday(const char *check, size_t len);

/* for unit test 4781 from parsedate.c:264 */
UNITTEST int checkmonth(const char *check, size_t len);

/* for unit test 4781 from parsedate.c:336 */
UNITTEST int checktz(const char *check, size_t len);

/* for unit test 1636 from progress.c:37 */
UNITTEST void time2str(char *r, size_t rsize, curl_off_t seconds);

/* for unit test 1636 from progress.c:86 */
UNITTEST char *max6out(curl_off_t bytes, char *max6, size_t mlen);

/* for unit test 1606 from progress.c:130 */
UNITTEST CURLcode pgrs_speedcheck(struct Curl_easy *data,
                                  const struct curltime *pnow);

/* for unit test 1614 from proxy.c:55 */
UNITTEST bool cidr4_match(const char *ipv4,    /* 1.2.3.4 address */
                          const char *network, /* 1.2.3.4 address */
                          int bits);

/* for unit test 1614 from proxy.c:103 */
UNITTEST bool cidr6_match(const char *ipv6, const char *network,
                          int bits);

/* for unit test 1614 from proxy.c:214 */
UNITTEST bool proxy_check_noproxy(const char *name, const char *no_proxy);

/* for unit test 1309 from splay.c:175 */
UNITTEST struct Curl_tree *splayinsert(timediff_t key,
                                       struct Curl_tree *root,
                                       struct Curl_tree *node,
                                       uint32_t id);

/* for unit test 1309 from splay.c:238 */
UNITTEST struct Curl_tree *splaygetbest(timediff_t key,
                                        struct Curl_tree *root,
                                        struct Curl_tree **removed);

/* for unit test 1309 from splay.c:310 */
UNITTEST int splayremove(struct Curl_tree *root,
                         struct Curl_tree *removenode,
                         struct Curl_tree **newroot);

/* for unit test 3301 from thrdqueue.c:375 */
UNITTEST CURLcode thrdq_await_done(struct curl_thrdq *tqueue,
                                   uint32_t timeout_ms);

/* for unit test 3211 from u8_strset.c:255 */
UNITTEST CURLcode u8_strset_set(struct u8_strset *set,
                                uint8_t id, const char *str);

/* for unit test 3211 from uint-bset.c:72 */
UNITTEST uint32_t uint32_bset_capacity(struct uint32_bset *bset);

/* for unit test 3213 from uint-spbset.c:45 */
UNITTEST void uint32_spbset_clear(struct uint32_spbset *bset);

/* for unit test 3212 from uint-table.c:82 */
UNITTEST void uint32_tbl_clear(struct uint32_tbl *tbl);

/* for unit test 1675 from urlapi.c:124 */
UNITTEST CURLUcode urlencode_str(struct dynbuf *o, const char *url,
                                 size_t len, bool relative,
                                 unsigned int query);

/* for unit test 1675 from urlapi.c:276 */
UNITTEST CURLUcode parse_hostname_login(struct Curl_URL *u,
                                        const char *login,
                                        size_t len,
                                        unsigned int flags,
                                        size_t *hostname_offset);

/* for unit test 1653 from urlapi.c:383 */
UNITTEST CURLUcode parse_port(struct Curl_URL *u, struct dynbuf *host,
                              bool has_scheme);

/* for unit test 1675 from urlapi.c:462 */
UNITTEST CURLUcode ipv6_parse(struct Curl_URL *u, char *hostname,
                              size_t hlen);

/* for unit test 1675 from urlapi.c:568 */
UNITTEST int ipv4_normalize(struct dynbuf *host);

/* for unit test 1395 from urlapi.c:834 */
UNITTEST int dedotdotify(const char *input, size_t clen, char **outp);

/* for unit test 1675 from urlapi.c:942 */
UNITTEST CURLUcode parse_file(const char *url, size_t urllen, CURLU *u,
                              const char **pathp, size_t *pathlenp);

/* for unit test 3217 from vdns/dnscache.c:62 */
UNITTEST void dnsc_peer2id(struct dnsc_id *pid, char type,
                           struct Curl_peer *peer);

/* for unit test 3217 from vdns/dnscache.c:86 */
UNITTEST void dnsc_id2key(struct dnsc_key *key, struct dnsc_id *id);

/* for unit test 3271 from vdns/dnscache.c:101 */
UNITTEST bool dnsc_id_matches_entry(struct dnsc_id *id,
                                    struct Curl_dns_entry *dns);

/* for unit test 1608 from vdns/dnscache.c:403 */
UNITTEST CURLcode dns_shuffle_addr(struct Curl_easy *data,
                                   struct Curl_addrinfo **addr);

/* for unit test 1655 from vdns/doh.c:94 */
UNITTEST DOHcode doh_req_encode(const char *host,
                                DNStype dnstype,
                                unsigned char *dnsp,  /* buffer */
                                size_t len,  /* buffer size */
                                size_t *olen);  /* output length */

/* for unit test 1655 from vdns/doh.c:633 */
UNITTEST void de_init(struct dohentry *de);

/* for unit test 1650 from vdns/doh.c:643 */
UNITTEST DOHcode doh_resp_decode(const unsigned char *doh,
                                 size_t dohlen,
                                 DNStype dnstype,
                                 struct dohentry *d);

/* for unit test 1655 from vdns/doh.c:886 */
UNITTEST void de_cleanup(struct dohentry *d);

/* for unit test 1658 from vdns/doh.c:979 */
UNITTEST CURLcode doh_resp_decode_httpsrr(struct Curl_easy *data,
                                          const unsigned char *cp, size_t len,
                                          struct Curl_https_rrinfo **hrr);

/* for unit test 3400 from vquic/capsule.c:151 */
UNITTEST size_t capsule_encap_udp_hdr(uint8_t *hdr, size_t hdrlen,
                                      size_t payload_len);

/* for unit test 1657 from vtls/x509asn1.c:203 */
UNITTEST const uint8_t *getASN1Element(struct Curl_asn1Element *elem,
                                       const uint8_t *beg, const uint8_t *end);

/* for unit test 1666 from vtls/x509asn1.c:408 */
UNITTEST CURLcode encodeOID(struct dynbuf *store,
                            const uint8_t *beg, const uint8_t *end);

/* for unit test 1656 from vtls/x509asn1.c:497 */
UNITTEST CURLcode GTime2str(struct dynbuf *store,
                            const char *beg, const char *end);

/* for unit test 1667 from vtls/x509asn1.c:625 */
UNITTEST CURLcode ASN1tostr(struct dynbuf *store,
                            struct Curl_asn1Element *elem);
#endif /* UNITTESTPROTOS_H */
