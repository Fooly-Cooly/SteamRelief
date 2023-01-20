SteamRelief - A Steam RAM Limiter
=====================
<img src="/assets/256.webp" align="left" height="256" alt="Icon" />
Valve's ever increasing reliance on CEF for it's UI has left Steam a needless resource hog. So I made a little app that sits in the background and helps to keep it's RAM usage in check.

## Configuration
SteamRelief.ini
```
[Settings]
NoTray=0
StartSteam=1
LaunchParams=open/minigameslist

;-- NoTray ----------------------------------------
; Disables SteamRelief's tray icon
; Tray Icon Off	= 1
; Tray Icon On	= 0

;-- StartSteam ------------------------------------
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
; Inventory			"open/inventory"
; Music Player		"open/musicplayer"
; News				"open/news"
; Community			"url/CommunityHome"
; Friends activity	"url/SteamIDControlPage"
; Account Profile	"url/SteamIDMyProfile"
; StoreFrontPage	"url/StoreFrontPage"
; Wishlist			"url/UserWishlist"
```