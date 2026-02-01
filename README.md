[ORIGINAL README](https://github.com/acuteimmersive/openimmersive/blob/c4dac16dfc750e6c409c183a408d113982673ca7/README.md)

# A Fork of OpenImmersive

Last updated Feb. 1, 2026

Hello! This is a fork of the great work done by [Anthony Maës](https://www.linkedin.com/in/portemantho/) & [Acute Immersive](https://acuteimmersive.com/), derived from [Spatial Player](https://github.com/mikeswanson/SpatialPlayer/) by [Mike Swanson](https://blog.mikeswanson.com/).

So you know my context, I've been working on lightweight 3D video apps and utilities for macOS and visionOS. I was aware of OpenImmersive at its launch but since it didn't support SBS (side-by-side) video playback, I didn't pay much attention to it until version 1.6, where support was added.

The purpose of this fork is to refine some of the UI design of the container app, to reduce cognitive load and improve visual alignment. NONE of these changes are a criticism of the original design. Simply, they're my personal design preferences, which I do plan to document in this repo in the future, if you're a designer interested in such redesigns.

I also redesigned the app icon, probably for the worse, as it may deviate too much from existing OpenImmersive brand standards.

I have no plans to add major functionality to this fork except for tiny stuff. For example, the recent addition of toggling hands on and off.

Also, this fork uses multiple AI coding tools. So if you're looking for coding best practices and non-sloppy code, you my friend are checking out the wrong fork. Also, just because I say I'm trying to get the UI closer to the HIG, won't mean that I'll actually achieve it!

Finally, this repo doesn't touch the library package at all. I have zero interest at this time in modding the library, as I want to stay aligned with future changes. But that constraint is sometimes the reason why some of the UI is wacky (e.g. the lack of gaze highlights on the toolbar buttons).

## Redesign Rationale: Main Screen

Another thing I forgot to mention in the text below is that I wanted to square off and prevent resizing of the window. Resizing isn't necessary (there isn't more content to show and hide) and squaring perfectly centers the prominent play button, which is definitely a design feature I wanted to preserve in the redesign.

<img src="https://github.com/ntfromchicago/openimmersive/blob/be746fab61179a3daff40c837058a39e3959e903/OpenImmersive%20Main%20Screen%20Redesign.png">

## Redesign Rationale: Settings Screen

<img src="https://github.com/ntfromchicago/openimmersive/blob/bcd854cf4a4df6709edea70d01f49fc074ea2e3d/OpenImmersive%20Settings%20Screen%20Redesign.png">
