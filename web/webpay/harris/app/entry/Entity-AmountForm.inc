<div class="payment-accounts">
	<h2 class="StepTitle">Amount To Pay
		<span class="StepSummary">
			You may pay the entire amount owed or choose to 
			specify a different payment amount
		</span>
	</h2>
	<style>
		.pe .ownerSection {
			float:left;width:315px; text-align:left;padding-left: 20px; 
			}
		.pe .ownerSection a {
			font-weight:normal;font-size:13px;margin-bottom:2px;padding-bottom:0px;display:block;text-decoration:none;
			}
		.pe .paymentSection {
			float: left; width: 460px; margin-bottom: 10px;
			}
		.pe .account-error { border-radius:3px; background-color: #FEF1E9;
						font-family:Arial; color:red; text-align:right; padding:5px; font-weight:bold
						}
		hr.fade-hr { 
			border: 0; width: 70%; float:right; 
			height: 1px; margin: 5px 5px 15px 5px;
			background-image: -webkit-linear-gradient(left, #f0f0f0, #8c8b8b, #f0f0f0);
			background-image: -moz-linear-gradient(left, #f0f0f0, #8c8b8b, #f0f0f0);
			background-image: -ms-linear-gradient(left, #f0f0f0, #8c8b8b, #f0f0f0);
			background-image: -o-linear-gradient(left, #f0f0f0, #8c8b8b, #f0f0f0); 
		}
.input-help div {
    display: none;
}
/* Help should show when invalid */
 .xng-invalid + .xxinput-help {
    display: block;
}
input.ng-invalid { border: 2px solid red; color: red; }
input.ngMin + .input-help, input.ngMax + .input-help { display: block; }
input.ngMin + .input-help div.ngMin { display: block; color: red; }
input.ngMax + .input-help div.ngMax { display: block; color: green; }
	</style>
<form name="testForm">
	<!-- step content -->
	<div style="width:95%;"> 
		<div class="row" ng-repeat="account in payment.accounts">
			<div ng-if="$index > 0" style="clear:both;margin-bottom:10px;margin-top:30px;border-bottom:1px solid gray;"></div>
			<div style="padding:5px;padding-right:30px; xbackground-color:transparent;">
				<div class="pe">
					<div class="ownerSection">
						<div ng-if="clientRoot">
							<a tabindex="-1" href="{{clientRoot}}showdetail2.jsp?can={{account.account}}"> {{account.account}} </a>
							<div>CAD No: </div>
						</div>
						<div ng-if="!clientRoot" style="color:darkblue;font-weight:bold;margin-bottom:5px; display: flex;">
							<div style="margin-right:15px;">{{account.account}}</div>
							<div ng-if="showCad">CAD No: {{account.aprdistacc}} </div>
						</div>

                        <div ng-if="false && account.ownerAddress" ng-bind-html="renderHtml(account.ownerAddress)" style="color:darkgrey;margin-bottom: 5px;"> </div>
                        <div style="color:darkgrey;margin-bottom: 5px;">
                            <span ng-if="account.owner.name.length > 0">{{account.owner.name}}<br></span>
                            <span ng-if="account.owner.address1.length > 0">{{account.owner.address1}}<br></span>
                            <span ng-if="account.owner.address2.length > 0">{{account.owner.address2}}<br></span>
                            <span ng-if="account.owner.address3.length > 0">{{account.owner.address3}}<br></span>
                            <span ng-if="account.owner.city.length > 0">{{account.owner.city}}</span>
                            <span ng-if="account.owner.city.length > 0 && account.owner.state.length > 0">, </span>
                            <span ng-if="account.owner.state.length > 0">{{account.owner.state}}</span>
                            <span ng-if="account.owner.city.length > 0 || account.owner.state.length > 0"> &nbsp; </span>
                            <span ng-if="account.owner.zipcode.length > 0">{{account.owner.zipcode}}</span>
                        </div>

						<div ng-if="account.description" style="color:darkblue;font-weight:bold;">
							{{account.description}}
						</div>
					</div>
					<div class="paymentSection">
						<div style="float:right;">
							<div style="float:left;width:250px;text-align:right;"> This is the amount you owe: </div>
							<div style="float:left;width:150px;text-align:right;"> {{account.amountDue | currency}} </div>
						</div>
						<div style="clear:both;"></div>

						<div ng-if="account.amountPending && account.amountPending > 0">
							<div style="float:right;margin-top:10px;">
								<div style="float:left;width:250px;text-align:right;color:red;"> 
									Pending payments:
									<div style="font-size:10px;color:red;font-style:italic;padding-right:5px;">
										(not reflected in amount owed above)
									</div>
								</div>
								<div style="float:left;width:150px;text-align:right;color:red;"> 
									{{account.amountPending | currency}} 
								</div>
							</div>
							<div style="clear:both;"></div>
						</div>

						<div ng-if="account.hasScheduled == true">
							<div style="float:right;margin-top:10px;">
								<div style="float:left;width:400px;text-align:left;color:red;text-align:right;"> 
									<span style='font-weight: bold;'>Important: </span>
									This account has a scheduled payment in the future.<br>
								</div>
							</div>
							<div style="clear:both;"></div>
						</div>


						<!-- Fixed payments - User is not allowed to change the payment information -->
						<div ng-if="account.paymentType && account.paymentType == 'fixed'">
							<div ng-if="account.paymentYear && account.paymentYear.length > 0">
								<div style="float:right;margin-top:15px;">
									<div style="float:left;width:250px;text-align:right;"> Apply payment to  year: 
										<div style="font-size:10px;color:red;font-style:italic;padding-right:5px;">
											(the specified year is paid first)
										</div> 
									</div>
									<div style="float:left;width:150px;text-align:right;"> {{ account.paymentYear }} </div>
								</div>
							</div>
							<div style="clear:both;"></div>

							<div class="alternate-payment-amount" style="float:right;margin-top:15px;">
								<div style="float:left;width:250px;"> 
									<label style="float:right;" for="pay-{{account.account}}-type-partial">
										Payment amount: 
									</label>
								</div>
								<div style="float:left;width:150px;text-align:right;"> 
									{{account.paymentAmount | currency}} 
								</div>
							</div>
						</div>


						<div ng-if="account.paymentType && account.paymentType == 'escrow'">
							<div style="float:right;margin-top:15px;">
								<div style="float:left;width:250px;text-align:right;"> Apply payment to  year: </div>
								<div style="float:left;width:150px;text-align:right;"> Escrow </div>
							</div>
							<div style="clear:both;"></div>

							<div class="alternate-payment-amount" style="float:right;margin-top:15px;margin-bottom:10px;">
								<div style="float:left;width:270px;">
									<label style="float:right;" for="pay-{{account.account}}-type-partial">
										Payment amount: 
									</label>
								</div>
								<div style="float:left;width:150px;text-align:right;position:relative;">
									<input type="text" class="payment-amount" size="10px"
												id="pay-{{account.account}}-payment-partial" 
												name="pay-{{account.account}}-payment-partial" 
												ng-model="account.paymentAmount"
												ng-change="escrowPayment($index)" data-blur-currency
												
												x-ng-max="{{account.paymentYear == 'Escrow' ? '' : account.amountDue}}"
												value="{{account.paymentAmount | currency}}" 
												style="text-align:right;">
									<label for="pay-{{account.account}}-payment-partial" style="display:none;">
										partial payment amount
									</label>
								</div>
							</div>
							<div style="clear:both;"></div>
						</div>

						<div ng-if="(account.paymentType != 'fixed' && account.paymentType != 'escrow')">
							<div ng-if="account.yearsDue && account.yearsDue.length > 1">
								<div style="float:right;margin-top:15px;">
									<div style="float:left;width:250px;text-align:right;"> 
										<label for="pay-{{account.account}}-year">Apply payment to year: </label>
										<div style="font-size:10px;color:red;font-style:italic;padding-right:5px;">
											(the specified year is paid first)
										</div> 
									</div>
									<div style="float:left;width:150px;text-align:right;"> 
										<select id="pay-{{account.account}}-year" name="pay-{{account.account}}-year" ng-model="account.paymentYear"
														ng-change="paymentYearChange($index)">
											<option ng-selected="{{account.paymentType == 'lien' || account.paymentYear.length == 0}}" value=""> Any year owed </option>
											<option value="" disabled style="color:lightgrey;"> &mdash;&mdash;&mdash;&mdash;&mdash; </option>
											<option ng-selected="{{year.year == account.paymentYear}}" ng-repeat="year in account.yearsDue" value="{{year.year}}"> {{year.year}} </option>
											<option ng-if="account.allowEscrow" value="" disabled> </option>
											<option ng-if="account.allowEscrow" ng-selected="{{'Escrow' == account.paymentYear}}" value="Escrow"> Escrow </option>
										</select>
									</div>
								</div>
								<div style="clear:both;"></div>
							</div>

							<div style="float:right;margin-top:20px;">
								<div style="float:left;width:270px;text-align:right;"> 
									<input tabindex="-1" type="radio" class="payment-option" style="float:left;margin-left: 70px;" 
														id="pay-{{account.account}}-{{$index}}-type-full" 
														name="pay-{{account.account}}-{{$index}}-type"
														value="full"
														ng-model="account.paymentType"
														ng-change="fullPayment($index)" 
														ng-checked="{{account.paymentType == 'full' || account.paymentAmount == account.amountDue}}">
									<label for="pay-{{account.account}}-{{$index}}-type-full">Pay the amount owed: </label>
								</div>
								<div style="float:left;width:150px;text-align:right;"> {{account.amountDue | currency}} </div>
							</div>
							<div style="clear:both;"></div>

							<div class="alternate-payment-amount" style="float:right;margin-top:15px;margin-bottom:10px;">
								<div style="float:left;width:270px;"> 
									<div style="font-size:14px;color:red;float:left;width:40px;font-weight:bold;float:left;">OR</div> 
									<input tabindex="-1" type="radio" class="payment-option" style="float:left; margin-left: 28px;margin-right: 8px;"
														id="pay-{{account.account}}-{{$index}}-type-partial" 
														name="pay-{{account.account}}-{{$index}}-type"
														value="partial"
														ng-model="account.paymentType"
														ng-checked="{{account.paymentType == 'partial'
																	|| (account.paymentType != 'lien' && account.paymentAmount != account.amountDue)}}">
									<label style="float:right;" for="pay-{{account.account}}-{{$index}}-type-partial">Pay a different amount: </label>
								</div>
								<div style="float:left;width:150px;text-align:right;position:relative;">
									<input type="text" class="payment-amount" size="10px"
												id="pay-{{account.account}}-{{$index}}-payment-partial" 
												name="pay-{{account.account}}-{{$index}}-payment-partial" 
												ng-model="account.paymentAmount"
												ng-change="partialPayment($index)" 
												data-blur-currency
												ng-min="{{account.minPaymentAmount ? account.minPaymentAmount : '0'}}"
												ng-max="{{account.maxPaymentAmount ? account.maxPaymentAmount : '0'}}"
												value="{{account.paymentAmount | currency}}" style="text-align:right;"> 
									<label for="pay-{{account.account}}-{{$index}}-payment-partial" style="display:none;">partial payment amount</label>
								</div>
							</div>
							<div style="clear:both;"></div>


							<div ng-if="account.amountLien > 0">
								<div class="alternate-payment-amount" style="float:right;margin-top:5px;">
									<hr class="fade-hr">
									<div style="float:right;margin-top:0px;margin-bottom:15px;">
										<div style="float:left;width:250px;text-align:right;color:red;"> 
											This account has a lien:
											<div style="font-size:10px;color:red;font-style:italic;padding-right:5px;">(included in amount owed above)</div>
										</div>
										<div style="float:left;width:150px;text-align:right;color:red;"> {{account.amountLien | currency}} </div>
									</div>
									<div style="clear:both;"></div>

									<div style="float:left;width:270px;"> 
										<div style="font-size:14px;color:red;float:left;width:40px;font-weight:bold">OR</div> 
										<input tabindex="-1" type="radio" class="payment-option" style="float:left;margin-left: 28px;margin-right:10px;"
														id="pay-{{account.account}}-type-lien" 
														name="pay-{{account.account}}-type"
														value="lien"
														ng-model="account.paymentType"
														ng-change="lienPayment($index)" 
														ng-checked="{{account.paymentType == 'lien'}}">
										<label style="float:right;" for="pay-{{account.account}}-type-lien">Pay Lien: </label>
									</div>
									<div style="float:left;width:150px;text-align:right;"> {{account.amountLien | currency}} </div>
								</div>
								<div style="clear:both;"></div>
							</div><!-- Sample LIEN section - END -->
						</div>
						<div ng-if="account.error" class="account-error">{{account.error}}</div>
					</div><!-- End paymentSection  -->
				</div><!-- PE -->
			</div><!-- block --> 
		</div><!-- end repeat -->
	</div><!-- end width -->
</form>
</div>