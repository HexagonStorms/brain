---
name: plaza-codes-business-plan
description: "Lead-gen and pricing plan for Plaza Codes (July 2026) — Portland local small-biz focus, pricing tiers, ranked lead channels, sequencing"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1d008565-787c-4713-989e-e1dbf43eaac7
  modified: 2026-07-24T05:45:41.687Z
---

Business plan for Plaza Codes, set July 2026. Target: Portland-local small businesses (restaurants, therapists, doctors, creatives, shops) needing sites, revamps, or apps. Positioning: real human, senior engineer (Amazon/Silent Hill background), affordable vs agencies, local, will meet in person.

## Pricing (agreed floor/ranges)
- Brochure site (4–8 pages): $2,500–4,500. Floor ~$1,500, never below.
- Site revamp / migration: $1,500–3,500.
- E-commerce / booking: $4,000–8,000.
- Custom app / MVP: $10k+ or ~$100–140/hr, quoted weekly until scope is real.
- **Hosting & care plan: from $50/mo for new clients** (Jo's decision July 2026; advertised as "from $50/mo" on the landing page). Current plaza-billing $9–15/mo is commodity-priced; the care plan is the real recurring business.
- Framing: clients compare against Squarespace DIY and $15–25k agencies, not other devs. Underpricing signals risk, not value.

## Lead channels (ranked — INBOUND FIRST, per Jo's explicit direction July 2026)
Jo refuses cold outbound: **no walk-ins, no flyer drops, no cold face-to-face — do not suggest these again.** Cold email/DM/paper outreach also deprioritized ("textbook marketing that doesn't work"). Mixers/association events are fine (everyone opted in). Plan is built on people who are already looking.
1. **Google Search Ads (primary):** buy "website designer portland"-type intent queries. ~$6–12 CPC; $1,000/mo ≈ 100 visits ≈ 5–10 inquiries ≈ 1–2 projects/mo; CAC $500–1,000 vs $3,500 project + care plan LTV. **Landing page BUILT and live at https://plaza.codes/start/** (July 2026; Jo rejected /portland and /pdx — wanted a non-location path): pricing, FAQ, quote form firing GA4 `generate_lead` event (homepage form fires it too, `form_location` distinguishes them). Full click-by-click campaign setup doc: `docs/plans/google-ads-campaign.md` in plaza-codes-site (Jo runs ads himself, no PPC manager). Still missing on the page: a real client testimonial (get MyArtStarz's).
2. **Google Business Profile + reviews:** free half of the same channel (Maps pack); reviews from MyArtStarz + Cascade.
3. **Nextdoor + Portland small-biz Facebook groups:** answer "anyone know a web person?" recommendation posts — inbound, they asked.
4. **Existing network:** testimonials + referral asks (MyArtStarz, Cascade); Past Lives Makerspace members.
5. **Neighborhood business associations:** Venture Portland / Pearl District Business Association mixers.
6. **Thumbtack/Bark experiment:** $100–200 test, leads shared with ~5 pros, kill in a month if garbage.

## Hiring for lead gen
Freelance Google Ads manager: $300–600/mo management + ad spend, month-to-month, Jo owns the ad account, demand search-terms reports. Red flags: "guaranteed leads," long contracts, agency owns account. "Lead generation agencies" are spam farms — avoid. Option: Claude builds the campaign structure with Jo, skip the manager until spend justifies one.

## Site gaps to fix
- No testimonials on plaza.codes (get MyArtStarz first).
- No local signal — "Portland, OR" nowhere on the site; add to hero/footer/About.

## Sequencing
- This week: testimonial + referral asks, GBP setup.
- This month: join Pearl district association, start 10/week outreach list.
- This quarter: care plan from $50/mo for new clients.

Related: [[plaza-codes-cloudflare-cache]], [[hetzner-vps]].
