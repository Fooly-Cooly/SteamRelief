SteamRelief - A Steam RAM Limiter
=====================
<img src="/assets/256.webp" align="left" height="256" alt="Icon" />

### About
Valve's ever increasing reliance on CEF for it's UI has left Steam a needless resource hog. So I made a little app that sits in the background and helps keep it's RAM usage in check.

### Features
```
- Automatically cleans Steam's RAM every 10 seconds
- Start Steam with starting page of choice
- Hover over SteamRelief's tray icon for current Steam RAM usage (May take acouple tries)
- Click SteamRelief's tray icon to open last used Steam window
- Disable SteamRelief's tray icon
```

## Configuration - SteamRelief.ini
```
[Settings]
NoTray=0
StartSteam=1
LaunchParams=open/minigameslist

;-- NoTray --------------------------------------
; Disables SteamRelief's tray icon
; Tray Icon Off	= 1
; Tray Icon On	= 0

;-- StartSteam ----------------------------------
; Run Steam on SteamRelief startup
; Start Steam	= 1
; Don't Start	= 0

;-- LaunchParams --------------------------------
; Steam startup default page
; Large Games		"nav/games"
; Large Games		"open/largegameslist"
; Mini Games		"open/minigameslist"
; Big Picture Mode	"open/bigpicture"
; Friends List		"open/friends"
; Inventory		"open/inventory"
; Music Player		"open/musicplayer"
; News			"open/news"
; Community		"url/CommunityHome"
; Friends activity	"url/SteamIDControlPage"
; Account Profile	"url/SteamIDMyProfile"
; StoreFrontPage	"url/StoreFrontPage"
; Wishlist		"url/UserWishlist"
```
