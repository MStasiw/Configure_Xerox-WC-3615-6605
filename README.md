# Configure_Xerox-WC-3615-6605
Automates the manual work one would need to do to set/modify values of HTML form input elements per sets of settings related to select protocols supported on Xerox WorkCentre 3615, 6605, and possibly related models in this model/product family of multifunction printers/devices (MFPs/MFDs).

*Only having access to WorkCentre 3615 and 6605 models to test and verify on, but should work with any related models that have the exact same web application interface (EWS aka CWIS according to Xerox).*

Collection of Windows PowerShell Scripts, which can be executed:
- individually, or
- through nested execution of the wrapper/parent script `WC 3615 & 6605_InputLoop.Wrapper.ps1` which calls all included subscripts against each valid and ICMP reachable network printer which is specified by IP or DNS address in a text file (newline delimited) who's filepath must be specified as an argument.

## Implementation ##
Through reverse-engineering of HTML and JavaScript of web pages servered by the printer's Embedded Web Server (EWS), also known as 'CWIS' on older Xerox models and documentation, determined parameters and value syntax which is then used for HTTP POST transactions to submit changes.

#### Note: ####
 - ***Form values are hardcoded with that which is approapriate for printers in a Walmart Canada network environment, but can easily be substituted for whatever is approapriate for your network/preferences.***
 - ***In case privilaged administrator access is enabled on an individual printer (utilizing HTTP Basic Authentication), the Xerox default publicly disclosed password is hardcoded for dynamically encoding credentials passed in the Basic Authentiation type Request Header. If not required then they are just ignored. These too can be substituated for credentials applicable to your environment.***
