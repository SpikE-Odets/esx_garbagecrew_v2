This is a complete rewrite of my GarbageCrew script.  This version allows for anyone on the server to pull a bag and place it into the truck that started the job as long as the truck is still near the bin.  The person that pulls the garbage truck out will have to have the garbage job, but anyone can pull a bag out of a bin and place it into the truck and get paid no matter the job they have.

This version also puts all pay on server side to keep lua injectors from requesting pay to make it more secure.  Also makes it alot easier to add new collection spots in the Config.

This is a the next step in my Garbagejob_v2 to turn it into a Crew related job. Most servers you can rob a bank with 1 - 4 people, rob a store with 1-4 people, but any legal work must be done solo. This shows it can be done - with the pay split between everyone that is doing the job. I have spent a fair bit of time testing the networking on my personal test server, on a live dev server with 2-3 people helping me, and as of the last 12hrs live on 2 seperate servers.

To help with some of the questions:

* Only the "JobBoss" needs to pull out vehicle.
* Each member will receive even split of pay right after the last bag is placed into the truck.

The original creator is listed on the copy that I received are:

-- ORIGINAL SCRIPT BY Marcio FOR CFX-ESX

Changes to my version of script:

* added: Anyone can help take bags out of a bin and place inside the truck.
* added: Pay is sent after every pickup (in case driver disconnects)
* added: Pay is split among everyone that puts bags into the truck.
* added: Changed the draw location of the back of the trunk to use platelight.(even if vehicle is blown up still finds the platelight)

Changes to the original script:

* added: bag collection to each destination. (driver will have to get out to collect bags from trash bin.)
* added: pay per bag - the more you do the more you earn.
* added: animations from heist "Series A Funding" for walking while holding bag, and putting bag in truck.
* added: check for last job to keep from getting sent to the same job over and over.

-- Requires--

ESX_Jobs

-- Install --

* Import garbagejob_v2.sql if you do not already have the garbagejob on your server for work clothes settings.
* add esx_garbagecrew to your resource folder.
* start esx_garbagejobcrew in your server.fg

