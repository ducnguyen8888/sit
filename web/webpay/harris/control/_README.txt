


getConfigData.jsp
Retrieves general configuration information specific to the client, i.e. client_id, datasource, isTest, processor information



getPaymentInformation.jsp
Retrieves the account information to be paid, i.e. client, owner, year/month, amount, etc.
Can include default contact information


clearCart.jsp
Clears paid accounts from the SIT cart


processPaymentJPMC.jsp
Processes the payment, creates database record in SB status
!IMPORTANT: This page has the datasource HARDCODED but the getConfigData and getPaymentData pull the datasource from the configuration file.
		 This needs to be standardized.


** Other pages:
Carry over from websites, probably not used.

