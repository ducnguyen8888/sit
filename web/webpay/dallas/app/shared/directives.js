
app.directive("paymentAmounts", function() {
    return {
        restrict: 'E',
        replace: 'false',
        templateUrl: "app/entry/Entity-AmountForm.inc?"+Date.now()
    };
});
app.directive("paymentMethod", function() {
    return {
        restrict: 'E',
        replace: 'false',
        templateUrl: "app/entry/Entity-MethodForm_CreditCard.inc"
    };
});
app.directive("paymentContact", function() {
    return {
        restrict: 'E',
        replace: 'false',
        templateUrl: "app/entry/Entity-ContactForm.inc"
    };
});


// Specify "data-blur-currency" or "blur-currency" on the input element
app.directive("blurCurrency",function($filter) {
    return {
        restrict: "A",
        scope: true,
        require: "ngModel",
        link: function(scope, el, attrs, ngModelCtrl) {
                        function formatter(value) {
                            if ( ! value || value == "" ) return "";

                            value = parseFloat(value.toString().replace(/[^0-9._-]/g, '')) || 0;
                            if ( value < 0 || value == "" ) {
                                value = 0;
                            }
                            if ( value > 0 ) {
                                var minValue = 0;
                                if ( attrs.ngMin ) {
                                    minValue = parseFloat(attrs.ngMin.toString().replace(/[^0-9.]/g, '')) || 0;
                                    if ( value < minValue ) {
                                        console.log("User payment amount ("
                                                    + value + ") less than allowed minimum. Resetting: " + minValue);
                                        value = minValue;
                                        setTimeout(function() {
                                                alert("You may not pay less than what you owe.\n\n"
                                                        + "The payment amount has been changed to the amount owed.");
                                                    },1);
                                    }
                                }
                                if ( attrs.ngMax ) {
                                    var maxValue = parseFloat(attrs.ngMax.toString().replace(/[^0-9.]/g, '')) || Infinity;
                                    if ( maxValue < minValue ) maxValue = minValue;
                                    if ( value > maxValue ) {
                                        console.log("User payment amount ("
                                                    + value + ") exceeded allowed maximum. Resetting: " + maxValue);
                                        value = maxValue;
                                        setTimeout(function() {
                                                alert("You may not pay more than you owe.\n\n"
                                                        + "The payment amount has been changed to the amount owed.");
                                                    },1);
                                    }
                                }
                            }

                            var formattedValue = $filter('currency')(value);
                            el.val(formattedValue);
                            ngModelCtrl.$setViewValue(formattedValue.replace(/[^0-9._-]/g, ''));

                            return formattedValue;
                        }
                        ngModelCtrl.$formatters.push(formatter);

                        el.bind('focus', function() {
                            // To clear the input field on focus uncomment this line
                            //el.val("");

                            // This removes all non-numeric formatting of the value
                            el.val(el.val().replace(/[^0-9._-]/g, ''));
                        });

                        el.bind('blur', function() {
                            //var val = el.val().replace(/[^0-9._-]/g, '');
                            if ( el.val() ) formatter(el.val());
                        });
                }
    };
}).$inject = ['$filter'];
// //////////////////////////////////


app.directive("formatCreditcard",function($filter) {
    return {
        restrict: "A",
        scope: true,
        require: "ngModel",
        link: function(scope, elem, attrs, ngModelCtrl) {
                        function formatter(value) {
                            var cardtype   = UNKNOWN;
                            var isvalid    = false;

                            var cardnumber = value;

                            elem.removeClass("amex-card visa-card mastercard-card discover-card");
                            cardnumber = cardnumber ? cardnumber.replace(/[^0-9]/g,"") : "";
                            if ( cardnumber && cardnumber.length > 0 ) {
                                switch ( cardnumber.charAt(0) ) {
                                    case "4": cardtype = VISA; break;
                                    case "5": cardtype = MASTERCARD; break;
                                    case "6": cardtype = DISCOVER; break;
                                    case "3": cardtype = AMEX; break;
                                }
                                isvalid = (cardnumber.length == 16 || cardnumber.length == 13 || cardnumber.length == 15) && isValidCard(cardnumber);

                                switch ( cardtype ) {
                                    case VISA:       if ( ! elem.hasClass("visa-card") ) elem.addClass("visa-card"); break;
                                    case MASTERCARD: if ( ! elem.hasClass("mastercard-card") ) elem.addClass("mastercard-card"); break;
                                    case AMEX:       if ( ! elem.hasClass("amex-card") ) elem.addClass("amex-card"); break;
                                    case DISCOVER:   if ( ! elem.hasClass("discover-card") ) elem.addClass("discover-card"); break;
                                }
                            }

                            if ( cardtype == UNKNOWN ) {
                            } else if ( cardtype == AMEX ) {
                                if ( cardnumber.length > 4 )
                                    cardnumber = [cardnumber.slice(0,4), separatorChar,
                                                    cardnumber.slice(4)].join("");
                                if ( cardnumber.length > 11 )
                                    cardnumber = [cardnumber.slice(0,11), separatorChar,
                                                    cardnumber.slice(11)].join("");
                                if ( length == 5 || length == 12 )
                                    if ( trailing == " " || trailing == "-" ) 
                                        cardnumber += separatorChar;
                            } else {
                                for ( var position=4; position < cardnumber.length; position+=5 ) 
                                    cardnumber = [cardnumber.slice(0,position), separatorChar,
                                                    cardnumber.slice(position)].join("");
                                if ( length == 5 || length == 10 || length == 15 )
                                    if ( trailing == " " || trailing == "-" ) 
                                        cardnumber += separatorChar;
                            }

                            if ( isvalid ) {
                                if ( ! elem.hasClass("card-valid") ) elem.addClass("card-valid");
                            } else {
                                if ( elem.hasClass("card-valid") ) elem.removeClass("card-valid");
                            }

                            if ( value != cardnumber ) {
                                elem.val(cardnumber);
                                ngModelCtrl.$setViewValue(cardnumber);
                            }

                                //ctrl.$setValidity('ngMin', false);
                                //ctrl.$setValidity('parse', false);
                                //elem.addClass("ngMin");
                            return cardnumber;
                        }
                        ngModelCtrl.$formatters.push(formatter);

                        var UNKNOWN    = 0;
                        var AMEX       = 1;
                        var VISA       = 2;
                        var MASTERCARD = 3;
                        var DISCOVER   = 4;

                        var separatorChar = " ";

                        var isValidCard = function (val) { // luhnCheck(val) {
                            if ( ! val ) return false;
                            if ( val.length != 15 && val.length != 16 ) return false;

                            var sum = 0;
                            for (var i = 0; i < val.length; i++) {
                                var intVal = parseInt(val.substr(i, 1));
                                if (i % 2 == 0) {
                                    intVal *= 2;
                                    if (intVal > 9) {
                                        intVal = 1 + (intVal % 10);
                                    }
                                }
                                sum += intVal;
                            }
                            return (sum % 10) == 0;
                        }

                        //elem.bind('keydown', function(e) {
                            //var val = el.val().replace(/[^0-9._-]/g, '');
                        //	if ( ! elem.val() ) formatter(elem.val(),e);
                        //});
                        elem.bind('keyup', function(e) {
                            //var val = el.val().replace(/[^0-9._-]/g, '');
                            //if ( elem.val() ) formatter(elem.val(),e);
                            formatter(elem.val(),e);
                        });
                        elem.bind('change', function() {
                            //var val = el.val().replace(/[^0-9._-]/g, '');
                            if ( elem.val() ) formatter(elem.val());
                        });
                }
    };
}).$inject = ['$filter'];
// //////////////////////////////////
app.directive('ngDecimal', function () {
    return {
        restrict: 'A',
        require: 'ngModel',
        link: function (scope, elem, attr, ctrl) {
            scope.$watch(attr.ngMin, function () {
                ctrl.$setViewValue(ctrl.$viewValue);
            });
            var decimalValidator = function (value) {
                if ( value ) {
            console.log("Decimal: " + value + "   Round: " + Math.round(value));
                    value = Math.round(value,2);
                }
                return value;
            };

            ctrl.$parsers.push(decimalValidator);
            ctrl.$formatters.push(decimalValidator);
        }
    };
});


app.directive('ngCard', function () {
    return {
        restrict: 'A',
        require: 'ngModel',
        link: function (scope, elem, attr, ctrl) {
            scope.$watch(attr.ngCard, function () {
                ctrl.$setViewValue(ctrl.$viewValue);
            });
            var UNKNOWN    = 0;
            var AMEX       = 1;
            var VISA       = 2;
            var MASTERCARD = 3;
            var DISCOVER   = 4;

            var loop = 0;
            var isValidCard = function (val) { // luhnCheck(val) {
                    var sum = 0;

                    // Amex not allowed - after 8/1
                    if ( val && val.length > 1 && val.substring(1,1) == "3" ) return false;

                    for (var i = 0; i < val.length; i++) {
                        var intVal = parseInt(val.substr(i, 1));
                        if (i % 2 == 0) {
                            intVal *= 2;
                            if (intVal > 9) {
                                intVal = 1 + (intVal % 10);
                            }
                        }
                        sum += intVal;
                    }
                    return (sum % 10) == 0;
            }
            var creditCardIdentifier = function (cardnumber) {
                var cardtype   = UNKNOWN;
                var isvalid    = false;

                console.log("Checking CC Value: " + cardnumber);

                cardnumber = cardnumber ? cardnumber.replace(/[^0-9]/g,"") : "";
                if ( cardnumber ) {
                    console.log("Identifying card type");
                    switch ( cardnumber.charAt(0) ) {
                        case "4": cardtype = VISA; break;
                        case "5": cardtype = MASTERCARD; break;
                        case "6": cardtype = DISCOVER; break;
                        case "3": cardtype = AMEX; break;
                    }

                    isvalid = cardnumber.length == 16 && isValidCard(cardnumber);

                    switch ( cardtype ) {
                        case VISA:       if ( ! elem.hasClass("visa-card") ) elem.addClass("visa-card"); break;
                        case MASTERCARD: if ( ! elem.hasClass("mastercard-card") ) elem.addClass("mastercard-card"); break;
                        case AMEX:       if ( ! elem.hasClass("amex-card") ) elem.addClass("amex-card"); break;
                        case DISCOVER:   if ( ! elem.hasClass("discover-card") ) elem.addClass("discover-card"); break;
                    }
                }

                if ( cardtype == UNKNOWN ) {
                    elem.removeClass("amex-card visa-card mastercard-card discover-card");
                } else if ( cardtype == AMEX ) {
                } else {
                    for ( var position=4; position < cardnumber.length; position+=5 ) 
                        cardnumber = [cardnumber.slice(0,position), "-", cardnumber.slice(position)].join("");
                }

                if ( isvalid ) {
                    if ( ! elem.hasClass("card-valid") ) elem.addClass("card-valid");
                } else {
                    if ( elem.hasClass("card-valid") ) elem.removeClass("card-valid");
                }

                    //ctrl.$setValidity('ngMin', false);
                    //ctrl.$setValidity('parse', false);
                    //elem.addClass("ngMin");
                return cardnumber;
            };

            ctrl.$parsers.push(creditCardIdentifier);
            ctrl.$formatters.push(creditCardIdentifier);
        }
    };
});

