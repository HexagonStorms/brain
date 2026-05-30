---
name: reference-myartstarz
description: "myartstarz.com — client WordPress/WooCommerce site on Hetzner; repo, deploy flow, docroot, the retired plaza.codes alias"
metadata: 
  node_type: memory
  type: reference
  originSessionId: bcd0cdf7-868e-4bff-99cd-298336fdac06
---

MyArtStarz (client: Shelley Fluke, San Antonio children's art school). Live at **https://myartstarz.com**, WordPress + WooCommerce + custom FSE theme `myartstarz-fse`. Stripe payments. Parents register for classes and pay supply fees.

- **Hosting**: Hetzner VPS [[reference-hetzner-vps]] (5.78.148.196), NOT Cloudways. The repo's `deploy.sh` targets the old Cloudways box and is legacy/stale — do not use it.
- **Docroot**: `/var/www/myartstarz.plaza.codes/public/` (dir name is historical; it IS production). DB `myartstarz_plaza_codes_db`, prefix `mas_`, site user `myartstarz_plaza_codes`. WP `siteurl`/`home` = https://myartstarz.com.
- **Repo**: `HexagonStorms/myartstarz` (GitHub). Source of truth for the `myartstarz-fse` theme. Not cloned on elowynn by default.
- **Deploy**: rsync `wp-content/themes/myartstarz-fse/` to the docroot, then chown to `myartstarz_plaza_codes`. Goes straight to production (no separate staging). **Pull the server theme into the repo BEFORE deploying** — the live theme has been edited out-of-band, and `rsync --delete` will clobber untracked changes.
- **Retired alias**: `myartstarz.plaza.codes` was a temporary staging hostname pointing at the same docroot/db. Torn down 2026-05-30 — nginx block + cert removed (conf backup at `/root/teardown-backup-myartstarz-plaza-codes/`); docroot/db untouched. DNS record may still linger in Cloudflare. The `plaza-codes-vps` `site-remove.sh` now detects shared docroots and removes such aliases without deleting shared files/db/user.

Button labels come from a WooCommerce filter in the theme's `functions.php`: "Add to cart" → "Register Now" for classes/camps, "Pay Now" for supply-fee products (cats `supply-fees-district`/`supply-fees`).
