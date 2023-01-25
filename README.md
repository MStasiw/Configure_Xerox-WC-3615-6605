# Configure_Xerox-WC-3615-6605
Automates the manual work one would need to do to set/modify values of HTML form input elements per sets of settings related to select protocols supported on Xerox WorkCentre 3615, 6605, and possibly related models in this model/product family of multifunction printers/devices (MFPs/MFDs).

*Only having access to WorkCentre 3615 and 6605 models to verify on, but any related models with exact same web browser interface (EWS aka CWIS according to Xerox).*

Collection of Windows PowerShell Scripts, which can be called individually or through nested execution of the wrapper/parent script `WC 3615 & 6605_InputLoop.Wrapper.ps1` which calls all included subscripts.

## Implementation ##
Through reverse-engineering of HTML and JavaScript of web pages servered by the printer's Embedded Web Server (EWS), also known as 'CWIS' on older Xerox models and documentation, determined parameters and value syntax to used for HTTP POST transactions to submit changes.
