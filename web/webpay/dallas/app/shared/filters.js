
app.filter('hiddenAccountNumber', function () {
    return function (accountNumber) {
        if ( ! accountNumber || accountNumber.length < 4 )
            return accountNumber;

		return accountNumber.replace(/(.*)(.{4})$/,"... $2");
    }
});
