<div class="payment-method-form">
	<h2 class="StepTitle">Payment Information	
		<span class="StepSummary">
			Enter your payment method information
		</span>
	</h2>
	<style>
		.payment-method-form h4, .payment-method-form h5 { margin-left: 15px; }
		.payment-method-form label { margin-bottom: 10px; }
		.payment-method-form td label { margin-bottom: 0px; }
		.payment-method-form input { padding: 3px 5px; margin-top: -4px; }
		.payment-method-form select { padding: 3px 5px; }
		.payment-method-form div.error { font-size: 16px; color:blue ; }
		.card-identifier, span.card-valid { display: none; position: absolute; z-index: 10; padding-left: 15px; }
		#ccard-card-number  { border: 1px solid black; color: red; }
		#ccard-card-number.card-valid { border-color: green; color: green; }
		#ccard-card-number.card-valid ~ .card-valid { display: inline; color: green; padding-left: 115px; }
		#ccard-card-number.amex-card ~ .amex-card { display: inline; color: red; }
		#ccard-card-number.visa-card ~ .visa-card { display: inline; color: red; }
		#ccard-card-number.mastercard-card ~ .mastercard-card { display: inline; color: red; }
		#ccard-card-number.discover-card ~ .discover-card { display: inline; color: red; }
		#ccard-card-number.card-valid ~ .card-identifier { color: green; }

		#ccard-card-number.amex-card { color: red; }
		#amex-card-error { display: none; }
		#ccard-card-number.amex-card ~ #amex-card-error { display: inline; color: red; }
	</style>
	<!-- step content -->
	<div style="width:95%;">
		<div style="float:left;width:500px;">
			<h4 class="section_header"> CREDIT CARD INFORMATION </h4>
			<h5><i>Please enter your credit card information.</i></h5>
			<h6 ng-if="payment.method.notice" style="margin-left:15px;color:red;">* {{payment.method.notice}}</h6>
		</div>
		<div style="float:left;width:200px;padding: 5px 10px 10px 10px;text-align:left;">
			<img height="120" src="images/card_cvv-amex_visa_mc.jpg" style="float:right;" alt="Security code locations for credit cards"/><br>
			<h6><i> Credit Card Security Code</i><h6>
		</div>
		<div style="clear:both;height:20px;"></div>
		<div class="payment-summary-block">
				<div style="margin-left: 50px;">
					<table class="payment-metadata" border="0">
					<!--<tr>  <td colspan=3 style="padding-left:100px;">
						<img height="80" src="images/card_cvv-amex_visa_mc.jpg" alt="Security code locations for credit cards"/><br><br> </td></tr>
					<tr><td>&nbsp;</td></tr>-->
					<tr>  <th style="width:200px;padding-bottom:10px;"> 
							<label for="ccard-card-number"><span class="required-indicator">*</span>&nbsp;Credit&nbsp;Card&nbsp;Number:
							</label> 
						</th> 
						<td style="position:relative;"> 
							<input type="text" size=20 maxlength=19 id="ccard-card-number" name="card-number" 
										ng-model="payment.method.cardNumber" data-format-creditcard
										value="{{payment.method.cardNumber}}">
										<span class="card-identifier amex-card"> Amex </span>
										<span class="card-identifier visa-card"> Visa </span>
										<span class="card-identifier mastercard-card"> MasterCard </span>
										<span class="card-identifier discover-card"> Discover </span>
							<br>
							<div ng-if="payment.method.errors.cardNumber" id="method-card-error" class="error">{{payment.method.errors.cardNumber}}<br><br></div>
							<div id="amex-card-error" style="clear:both;" class="error">American Express Cards are not accepted<br><br></div>
						</td>
					</tr>
					<tr>  <th style="width:200px;padding-bottom: 10px;"> 
							<label for="ccard-cvv"><span class="required-indicator">*</span>&nbsp;Security Code:</label> 
						</th> 
						<td> 
							<input type="text" size=5 maxlength=5 id="ccard-cvv" name="card-cvv" 
									ng-model="payment.method.cvc" 
									value="{{payment.method.cvc}}"> 
							<div ng-if="payment.method.errors.cvc" id="method-cvc-error" class="error">{{payment.method.errors.cvc}}<br><br></div>
						</td>
					</tr>
					<tr>  <th style="width:200px;padding-top: 20px;"> <label><span class="required-indicator">*</span>&nbsp;Expiration: </label></th> 
						<td> 
							<div style="float: left;margin-right: 20px;">
									<label style="font-weight: normal;font-size:11px;" for="ccard-expiry-month">Month</label><br>
									<select id="ccard-expiry-month" name="card-expiry-month" ng-model="payment.method.expiryMonth"
										style="xmargin-top:5px;font-size:13px;">
										<option value="01"> 01 </option>
										<option value="02"> 02 </option>
										<option value="03"> 03 </option>
										<option value="04"> 04 </option>
										<option value="05"> 05 </option>
										<option value="06"> 06 </option>
										<option value="07"> 07 </option>
										<option value="08"> 08 </option>
										<option value="09"> 09 </option>
										<option value="10"> 10 </option>
										<option value="11"> 11 </option>
										<option value="12"> 12 </option>
									</select>
							</div>
							<div style="float: left;">
									<label style="font-weight: normal;font-size:11px;" for="ccard-expiry-year">Year</label><br>
									<select id="ccard-expiry-year" name="card-expiry-year" ng-model="payment.method.expiryYear"
										style="margin:0px;font-size:13px;">
										<option value="2016"> 2016 </option>
										<option value="2017"> 2017 </option>
										<option value="2018"> 2018 </option>
										<option value="2019"> 2019 </option>
										<option value="2020"> 2020 </option>
										<option value="2021"> 2021 </option>
										<option value="2022"> 2022 </option>
										<option value="2023"> 2023 </option>
										<option value="2024"> 2024 </option>
										<option value="2025"> 2025 </option>
										<option value="2026"> 2026 </option>
										<option value="2027"> 2027 </option>
										<option value="2028"> 2028 </option>
										<option value="2029"> 2029 </option>
										<option value="2030"> 2030 </option>
										<option value="2031"> 2031 </option>
										<option value="2032"> 2032 </option>
										<option value="2033"> 2033 </option>
										<option value="2034"> 2034 </option>
										<option value="2035"> 2035 </option>
										<option value="2036"> 2036 </option>
										<option value="2037"> 2037 </option>
										<option value="2038"> 2038 </option>
										<option value="2039"> 2039 </option>
										<option value="2040"> 2040 </option>
									</select>
							</div>
							<div style="clear:both;"></div>
							<div ng-if="payment.method.errors.expiry" id="method-expiry-error" class="error">{{payment.method.errors.expiry}}<br><br></div>
						</td>
					</tr>
					</table>
				</div>
		</div>
	</div><!-- end stop content -->
</div>

