# Prayer time sources: research report

Researched 25 October 2026. Every claim links to where it came from. Anything not confirmed is marked **unconfirmed**.

## Verdict

| Place | Tier | Source | Can we use it? | Plan |
|---|---|---|---|---|
| London | 2 Authority (and ELM jama'ah) | London Unified Prayer Timetable API | Good fit: start times, jama'ah times and both Asr times. **Permission granted by email, 25 Oct 2026** (see below). | Our daily API job fetches it with the key kept secret. |
| Saudi Arabia (Riyadh) | 2 Authority | Umm al-Qura Calendar (KACST) | No API. The terms don't grant reuse. The site says its times are **calculations** to the Umm al-Qura standard. | Calculate on the phone with the same method, then check it against the official CSV export. |
| Any mosque | 1 Mosque | Mawaqit, Masjidbox, MyMasjid | No public API for any of them. | Only mosques that give us permission and a feed. |
| Everywhere else | 3 Calculated | `adhan_dart` library (MIT) | Yes | Labelled "Calculated". |

## London: London Unified Prayer Timetable

- **What it is:** a shared timetable used by East London Mosque, London Central Mosque, Croydon ICT and others. "Times sourced from East London Mosque. We publish the official timetable without modification." Jama'ah times "reflect East London Mosque." ([site](https://www.londonprayertimes.com/))
- **API:** `GET https://www.londonprayertimes.com/api/times/?format=json&key=...`, with optional `date`, `year`, `month`, `city=london` and `24hours=true`. One date or a whole month per call. You request a key through a form, and they reply "normally within 4 hours" ([API page](https://www.londonprayertimes.com/api/)).
- **Response fields**, from the documented sample: `fajr`, `fajr_jamat`, `sunrise`, `dhuhr`, `dhuhr_jamat`, `asr`, `asr_2`, `asr_jamat`, `magrib` (spelt that way), `magrib_jamat`, `isha`, `isha_jamat`. So **jama'ah times and both Asr times are included**. `asr` is the earlier one (Shafi'i) and `asr_2` the later one (Hanafi); that's inferred from the order and still to be confirmed with real data.
- **Things to watch:**
  - Always send `24hours=true`. Without it, times come back in 12-hour format with no am/pm (e.g. `"dhuhr":"01:10"`).
  - The sample values are placeholders. The "2026-10-25" sample shows July times, so don't use them as test data.
  - There's no Hijri date in the response.
  - Times are added a year at a time ("2025 times added (24th Oct 2024)"). Next year's times may not exist until late October, so dates beyond the published data fall back to labelled calculated times.
- **Terms:** no terms page; the site only links Privacy and Contact. No licence, redistribution or attribution clause. "© London Unified Prayer Times." Contact: londonprayertimes@gmail.com.
- **Permission:** we asked by email to fetch the timetable daily through our own API job, republish it in our format for app users, cache it offline and credit it as "Source: London Unified Prayer Timetable (East London Mosque)". They replied on 25 October 2026 that it's okay to use. Keep that email; it's our record of permission.
- **Rejected:** the community library [`london-unified-prayer-times`](https://github.com/sshaikh/london_unified_prayer_times) reads the website's HTML. That's scraping, so we won't use it.

## Saudi Arabia: Umm al-Qura Calendar

- **Who:** "Developed and maintained by King Abdulaziz City for Science and Technology (KACST)". It's a registered government website ([ummulqura.org.sa](https://www.ummulqura.org.sa/en)).
- **Where the times come from**, from its FAQ: "The displayed prayer times are based on astronomical calculations according to Umm Al-Qura calendar standards used in Saudi Arabia." ([prayer times page](https://www.ummulqura.org.sa/en/prayer-times))
- **Export:** "you can export the displayed prayer times as PDF or CSV". That's ideal as test reference data.
- **Terms:** they cover use of the website only and say nothing about reuse in apps ([terms](https://www.ummulqura.org.sa/en/terms-and-conditions)). No API.
- **So:** the official times are themselves a calculation. If our calculation matches their export to the minute across a full year, we can honestly label it **"Umm al-Qura method (Saudi official standard)"** while still saying it was calculated on the phone.
- **Method:** Fajr 18.5°, Isha 90 minutes after Maghrib. The library docs recommend adding 30 minutes to Isha in Ramadan (120 in total). **Unconfirmed until we check the Ramadan dates in the official export.**
- **Jama'ah (iqamah):** no official nationwide schedule found. The rules found were local or temporary: Makkah during Hajj ([Bernama](https://www.bernama.com/en/news.php?id=2559338)), Ramadan Fajr and Isha ([Gulf News](https://gulfnews.com/world/gulf/saudi/saudi-arabia-orders-reduction-of-adhan-iqama-gap-to-10-minutes-for-fajr-and-isha-prayers-in-ramadan-1.94712564)). **Decision: Saudi times show the start (adhan) time only.**

## Mosque platforms

| Platform | Finding | Usable? |
|---|---|---|
| Mawaqit | "Our API is currently private and not publicly available." ([help](https://help.mawaqit.net/en/articles/11991838-can-i-use-your-api)). An [unofficial wrapper](https://github.com/Minemobs/mawaqit-api) exists. | No. The wrapper is unofficial, so it's rejected. |
| Masjidbox | "Masjidbox doesn't offer a public API for prayer times." Mosques can share an iCal link or export CSV ([support](https://support.masjidbox.com/does-masjidbox-have-a-public-api-for-prayer-times-sfnfd)). | Only if a mosque gives us its link and permission. |
| MyMasjid | No developer documentation found. | No |
| Smart Masjid | Per-mosque API key, seen only in a [WordPress plugin listing](https://fair.pm/packages/plugins/smart-masjid-prayer-timings/). **Unconfirmed.** | Only if a mosque opts in. |

**Decision:** in version 1, mosque selection lists only mosques that have permission behind them. East London Mosque (through the unified timetable) is the first. Others are added when a mosque opts in, which is a process with them, not new code.

## Calculation library

- [`adhan_dart`](https://pub.dev/packages/adhan_dart) 2.0.1: a port of the Adhan JavaScript library, MIT licence, published 5 months ago, 160 pub points. It supports Umm al-Qura, Muslim World League, Moonsighting Committee and more, Shafi'i and Hanafi Asr, and three high-latitude rules.
- Not chosen: [`adhan`](https://pub.dev/packages/adhan), last published about 3 years ago.

## UK summer Fajr and Isha (calculated times only)

- **There is no single agreed UK standard.** Methods in use include one-seventh of the night ([Salahtimes](https://www.salahtimes.com/faq/latitude), its UK default), a fixed 65 minutes for Isha ([SeekersGuidance](https://seekersguidance.org/answers/hanafi-fiqh/what-are-the-alternative-methods-to-isha-time-in-high-latitudes-when-isha-prayer-does-not-come-in/)), and others.
- `adhan_dart`'s own `recommended()` rule picks **Seventh of the Night above 48°** latitude.
- **Decision:** the calculated default is Muslim World League with Seventh of the Night, with a setting to change it. Official timetables always win, and they handle summer in their own way.

## Hijri date

- Umm al-Qura is a computed calendar. Communities that rely on moon sighting can differ by 1 to 3 days around Ramadan and Dhu al-Hijjah ([van Gent](https://webspace.science.uu.nl/~gent0113/islam/ummalqura_introduction.htm)).
- [`hijri`](https://pub.dev/packages/hijri) 3.0.1 converts to Umm al-Qura, but its algorithm is **unconfirmed**. Test value from the official site: **25 Oct 2026 = 14 Jumada al-Ula 1448**.
- **Decision:** show "Umm al-Qura" next to the Hijri date, with a ±1 day setting for UK users who follow moon sighting.
