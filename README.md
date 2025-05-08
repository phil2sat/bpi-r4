# BPI-R4 poe testing snapshot image 25/05/08

Hi, since im waiting for my device to arrive, i just decided to fire up my dev environment, take some time reading and fiddeling out what to do with the new hardware.

In first im not a professional dev, i dont know if the image is even booting ;)
So in this approach i only added some packages like luci a nice argon theme and the new firmware which should fix the txpower

Ah and used wpad-mesh-openssl since on my other devices i got the best compatibility in connecting wpa3 devices + im using mesh and never got it working with wpa3 encryption using the full package.

There are so many patches around but one says do apply next one dont, so first testing what works and what not.

Oh and i forgot i added some compiler optimizations, maybe they crash or make things go faster.

1. Is it able to boot at all
2. Does the wifi work as expected
3. Is the switch now able to handle 100mbit and 1000mbit devices properly without degrading all to 100mbit
4. Does the fan work as expected
5. everything else working/stable

I don't really know if the poe image works correctly on standard boards.

Here i will constantly updating fixed images if im able to fix it
https://github.com/phil2sat/bpi-r4

Hope someone could test if i'm able to build a running image as for my Archer-C7

Forum thread to report issues:
https://forum.banana-pi.org/t/bpi-r4-poe-testing-snapshot-image-05-08-25/23221

