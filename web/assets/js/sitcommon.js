    Number.prototype.c$valueOf = function() { 
        return this; 
    }
    Number.prototype.c$formatAsMoney = function() { 
        return "$"+(this.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,')); 
    }

    Number.prototype.c$toFixed = function(digits) {
        return this.toFixed((digits ? digits : 0));
    }
    Number.prototype.c$truncate = function(digits) {
        var factor = Math.pow(10,(digits ? digits : 0));
        return (parseInt(this * factor) / factor);
    }


    Number.prototype.c$add = function(amount,digits) {
        amount = (typeof amount == "number" ? amount : amount.c$valueOf ? amount.c$valueOf() : amount);
        var amountValue = this + (isNaN(amount) ? 0 : amount);
        return (typeof digits == 'undefined' ? amountValue : amountValue.toFixed(digits));
    }
    Number.prototype.c$subtract = function(amount,digits) { 
        amount = (typeof amount == "number" ? amount : amount.c$valueOf ? amount.c$valueOf() : amount);
        var amountValue = this - (isNaN(amount) ? 0 : amount);
        return (typeof digits == 'undefined' ? amountValue : amountValue.toFixed(digits));
    }
    Number.prototype.c$multiply = function(amount,digits) { 
        amount = (typeof amount == "number" ? amount : amount.c$valueOf ? amount.c$valueOf() : amount);
        var amountValue = this * (isNaN(amount) ? 0 : amount);
        return (typeof digits == 'undefined' ? amountValue : amountValue.toFixed(digits));
    }
    Number.prototype.c$divide = function(amount,digits) { 
        amount = (typeof amount == "number" ? amount : amount.c$valueOf ? amount.c$valueOf() : amount);
        var amountValue = this / (isNaN(amount) ? 0 : amount); // Yes, divide by 0 to throw an error
        return (typeof digits == 'undefined' ? amountValue : amountValue.toFixed(digits));
    }


    if (!String.prototype.startsWith) {
        String.prototype.startsWith = function(searchString, position) {
            position = position || 0;
            return this.indexOf(searchString, position) === position;
        };
    }

    String.prototype.c$valueOf = function() {
        return parseFloat(this.replace(/[^\d.-]/g,'')); 
    }
    String.prototype.c$formatAsMoney = function() { 
        return this.c$valueOf().c$formatAsMoney();
    }

    String.prototype.c$toFixed = function(digits) {
        return this.c$valueOf().c$toFixed(digits);
    }
    String.prototype.c$truncate = function(digits) {
        return this.c$valueOf().c$truncate((digits ? digits : 0));
    }

    String.prototype.c$add = function(amount,digits) {
        return this.c$valueOf().c$add(amount,digits);
    }
    String.prototype.c$subtract = function(amount,digits) {
        return this.c$valueOf().c$subtract(amount,digits);
    }
    String.prototype.c$multiply = function(amount,digits) {
        return this.c$valueOf().c$multiply(amount,digits);
    }
    String.prototype.c$divide = function(amount,digits) {
        return this.c$valueOf().c$divide(amount,digits);
    }
