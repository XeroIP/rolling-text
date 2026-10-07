# Rolling Text — Launch Posts

Copy-paste ready drafts for sharing Rolling Text.

---

## Show HN post

**Title** (80 char max — this one is 78):

```
Show HN: Rolling Text – a writing app where old words quietly disappear
```

**Body** (posts as the first comment under your submission):

```
I built this because I wanted somewhere to write down whatever's in my head
without it turning into a file I have to manage later. As you type, the
oldest text rolls off the front and is gone — nothing is saved, nothing is
stored, there's no undo history that survives it. When you close the app,
the words are gone too.

It's a Flutter app that runs on Android, iOS, and Web from one codebase.
A few things that turned out harder than I expected:

- Truncation has to operate on extended grapheme clusters, not code points,
  or it'll slice an emoji or accented character in half at the boundary.
- It has to preserve your cursor position and defer entirely while your
  keyboard's IME composition is active, or it'll corrupt text you're still
  mid-way through typing (e.g. composing an accented character or CJK input).
- Flutter's text field doesn't virtualize, so there's a real ceiling on how
  long the buffer can get before every keystroke re-lays-out the whole
  thing. Character limit tops out at 25,000 for that reason.

Try it in the browser, no install: https://xeroip.github.io/rolling-text/

Source (MIT licensed): https://github.com/XeroIP/rolling-text
Android APK: on the GitHub Releases page

It's a small, free, ad-free, no-account, no-analytics thing I built for
myself and figured other people might like too. Happy to answer questions
about the Flutter/Dart side or the truncation logic.
```

Notes:
- HN strongly prefers plain, unhyped language — the draft above avoids
  marketing words on purpose. Don't add exclamation points or "amazing."
- Post it yourself from your own HN account; submissions posted by someone
  else on the author's behalf get flagged.
- Best times to post are generally weekday mornings, US Eastern time.
- Be ready to reply to comments for the first hour or two — that's what
  keeps a Show HN alive on the front page.

---

## Reddit post (general template, reusable across subreddits)

**Title** (swap the bracketed hook line per subreddit, see list below):

```
I made a little app that forgets what you write on purpose — thought some of you might like it
```

**Body:**

```
Hey all — sharing something I've been building in my spare time, not
trying to sell anything, it's free and always will be.

It's called Rolling Text. The idea is simple: you write, and as you keep
typing, the oldest words quietly scroll off and disappear. Nothing is
saved. Nothing is stored. When you close it, whatever you wrote is gone.

I built it for the moments where I just want to get something out of my
head — venting, working through a thought, a stream-of-consciousness
brain dump — without ending up with a file or note I now have to deal
with later. No account, no cloud sync, no analytics, nothing to manage.

It runs right in the browser, no install needed:
https://xeroip.github.io/rolling-text/

There's also an Android APK on the GitHub releases page if you'd rather
have it as an app, and the source is fully open (MIT license) if you're
curious how it works or want to poke at it:
https://github.com/XeroIP/rolling-text

Not looking for anything from this beyond hearing what people think — if
it's useful to you, or if something about it is annoying, I'd genuinely
like to know either way.
```

Notes:
- This is written to be dropped into most subreddits with only the title's
  bracketed hook changed. Swap a line or two in the body if a subreddit's
  culture calls for it (see per-subreddit notes below).
- Check each subreddit's self-promotion rules before posting — many cap
  self-promo at a fraction of your post history, require a specific flair
  ("Show and Tell," "Self-Promotion Saturday" threads, etc.), or want you
  to have some karma/history in the sub first. A few minutes reading the
  sidebar/rules saves a removed post.
- Don't cross-post the identical text to many subreddits back-to-back in
  one sitting — Reddit's spam filters (and human mods) treat that as
  spam regardless of intent. Space posts out over days, and read the room
  in each community rather than blasting the same copy everywhere at once.

---

## Subreddits worth trying

Grouped by why the app fits. Check each one's self-promo rules first —
noted where a sub is known to be strict about it.

**Privacy / minimal-data audience**
- r/privacy — "nothing is saved" is the whole pitch here; strict about
  self-promo, read the rules first.
- r/degoogle — appeals to the no-account, no-cloud angle.
- r/privacytoolsIO — similar audience, may want you to note it's not a
  security tool per se, just a no-storage one.

**Writing / journaling / mental decluttering**
- r/journaling — frame it as a tool for morning-pages-style brain dumps.
- r/DecidingToBeBetter — "get it out of your head" framing fits well.
- r/writing — softer fit; frame as a scratchpad for freewriting, not a
  serious writing tool.
- r/GetDisciplined — brain-dump/decluttering angle.

**Open source / dev community**
- r/FlutterDev — dev audience, they'll appreciate the cross-platform
  build and the technical writeup (grapheme clusters, IME handling).
- r/opensource — straightforward open-source-project fit.
- r/coolgithubprojects — built specifically for sharing repos like this.
- r/SideProject — indie/solo-builder audience, low self-promo friction.
- r/androiddev — for the Android build specifically; keep it technical.

**Discovery-focused subs**
- r/InternetIsBeautiful — good fit since the web version needs zero
  install; this sub explicitly wants "try it now" links.
- r/SomebodyMakeThis — only if there's a matching old request thread;
  otherwise skip.

**Android app audience**
- r/androidapps — general Android app audience, straightforward fit
  for the APK angle.

Suggested order: start with r/InternetIsBeautiful or r/SideProject (lower
self-promo friction, good signal on whether the pitch lands), then branch
into r/privacy, r/journaling, and r/FlutterDev once you've got a couple of
comments' worth of feedback to refine the copy with.
