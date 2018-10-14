<div class="payment-contact-form">
	<h2 class="StepTitle">Contact Information	
		<span class="StepSummary">
			Enter your contact information. 
		</span>
	</h2>
	<style>
		td { text-align: left; color: green; padding-bottom: 15px; }
		table.payment-metadata .error { font-size: 10px; color: red; font-style: italic; }
	</style>

	<!-- step content -->
	<div style="width:95%;">
		<br><br>
		<div class="payment-summary-block contact">
				<div style="margin-left:20px;position:relative;display:none;">
					<img src="images/warning-icon-24.png" alt="Entry warnings" style="float:left;">
					<h3 id="user_message" style="color:red;float:left;"><%= warning_message %></h3>
				</div>
				<div style="clear:both;"></div>


				<table width="750" class="payment-metadata" border=0>

				<tr> <th> <div style="float:right; font-size: 12x;"><span id="req-country" style="display:none;" class="required-indicator">*</span> 
						<label for="payer-country">Country:</label> </div>
					</th> 
					<td class="requiredNONUS">
								<select id="payer-country" name="payer-country" ng-model="payment.contact.country">
									<option value="">Select Country if Foreign Residence</option>
									<option value="ALGERIA" >Algeria</option>
									<option value="ARGENTINA" >Argentina</option>
									<option value="AUSTRALIA" >Australia</option>
									<option value="AUSTRIA" >Austria</option>
									<option value="BELGIUM" >Belgium</option>
									<option value="BOLIVIA" >Bolivia</option>
									<option value="BRAZIL" >Brazil</option>
									<option value="BULGARIA" >Bulgaria</option>
									<option value="CANADA" >Canada</option>
									<option value="CHILIE" >Chile</option>
									<option value="CHINA" >China</option>
									<option value="COLOMBIA" >Colombia</option>
									<option value="COSTA RICA" >Costa Rica</option>
									<option value="CROATIA" >Croatia</option>
									<option value="CZECH REPUBLIC" >Czech Republic</option>
									<option value="DENMARK" >Denmark</option>
									<option value="DOMINICAN REPUBLIC" >Dominican Republic</option>
									<option value="ECUADOR" >Ecuador</option>
									<option value="EL SALVADOR" >El Salvador</option>
									<option value="ESTONIA" >Estonia</option>
									<option value="FINLAND" >Finland</option>
									<option value="FRANCE" >France</option>
									<option value="GERMANY" >Germany</option>
									<option value="GREECE" >Greece</option>
									<option value="GUATEMALA" >Guatemala</option>
									<option value="HONG KONG" >Hong Kong</option>
									<option value="HUNGARY" >Hungary</option>
									<option value="INDIA" >India</option>
									<option value="INDONESIA" >Indonesia</option>
									<option value="IRELAND" >Ireland</option>
									<option value="ISRAEL" >Israel</option>
									<option value="ITALY" >Italy</option>
									<option value="JAPAN" >Japan</option>
									<option value="KOREA" >Korea</option>
									<option value="LATVIA" >Latvia</option>
									<option value="LITHUANIA" >Lithuania</option>
									<option value="LUXEMBOURG" >Luxembourg</option>
									<option value="MALAYSIA" >Malaysia</option>
									<option value="MEXICO" >Mexico</option>
									<option value="MIDDLE EAST" >Middle East </option>
									<option value="MOROCCO" >Morocco</option>
									<option value="NETHERLANDS" >Netherlands</option>
									<option value="NEW ZEALAND" >New Zealand</option>
									<option value="NORWAY" >Norway</option>
									<option value="PANAMA" >Panama</option>
									<option value="PARAGUAY" >Paraguay</option>
									<option value="PERU" >Peru</option>
									<option value="PHILIPPINES" >Philippines</option>
									<option value="POLAND" >Poland</option>
									<option value="PORTUGAL" >Portugal</option>
									<option value="PUERTO RICO" >Puerto Rico</option>
									<option value="ROMANIA" >Romania</option>
									<option value="RUSSIA" >Russia</option>
									<option value="SINGAPORE" >Singapore</option>
									<option value="SLOVAKIA" >Slovakia</option>
									<option value="SLOVENIA" >Slovenia</option>
									<option value="SOUTH AFRICA" >South Africa</option>
									<option value="SOUTH EAST AFRICA" >South East Africa</option>
									<option value="SPAIN" >Spain</option>
									<option value="SWEDEN" >Sweden</option>
									<option value="SWITZERLAND" >Switzerland</option>
									<option value="TAIWAN" >Taiwan</option>
									<option value="THAILAND" >Thailand</option>
									<option value="TUNISIA" >Tunisia</option>
									<option value="TURKEY" >Turkey</option>
									<option value="UNITED KINGDOM" >United Kingdom</option>
									<option value="UNITED STATES" >United States</option>
									<option value="URUGUAY" >Uruguay</option>
									<option value="VENEZUELA" >Venezuela</option>
								</select>
					</td> 
				</tr>

				<tr> <th> <div style="float:right; font-size: 12x;"><span class="required-indicator">*</span> <label for="payer-name">Name:</label> </div></th>  
					<td class="requiredField"> 
						<input type="text" size=26 maxlength=40 id="payer-name" name="payer-name" ng-model="payment.contact.name"> 
						<div ng-if="payment.contact.errors.name" id="payer-name-error" class="error">{{payment.contact.errors.name}}</div>
					</td> 

				</tr>
				<tr> <th><div style="float:right; font-size: 12x;"> <span class="required-indicator">*</span> <label for="payer-street">Address:</label></div> </th> 
					<td class="requiredField"> <input type="text" size=30 maxlength=30 id="payer-street" name="payer-street" ng-model="payment.contact.street">
						<div ng-if="payment.contact.errors.street" id="payer-street-error" class="error">{{payment.contact.errors.street}}</div>
					</td> 
				</tr>
				<tr> <th> <div style="float:right; font-size: 12x;"><span class="required-indicator">*</span> <label for="payer-city">City:</label> </div> </th> 
					<td class="requiredField"> <input type="text" size=24 maxlength=24 id="payer-city" name="payer-city" ng-model="payment.contact.city">
						<div ng-if="payment.contact.errors.city" id="payer-city-error" class="error">{{payment.contact.errors.city}}</div>
					</td> 
				</tr>
				<tr> <th> <div style="float:right; font-size: 12x;">
						<span ng-if="! payment.contact.country || payment.contact.country == 'UNITED STATES'" id="req-state" class="required-indicator">*</span> 
						<label for="payer-state">State:</label> </div>
					</th> 
					<td class="requiredUS">
						<select id="payer-state" name="payer-state" size="1" ng-model="payment.contact.state">
									<option value=""> Select Your State </option>
									<option value="AA" >Armed Forces America (except Canada)</option>
									<option value="AE" >Armed Forces Europe, Canada, Middle East, Africa</option>
									<option value="AP" >Armed Forces Pacific</option>
									<option value="AL" >Alabama</option>
									<option value="AK" >Alaska</option>
									<option value="AZ" >Arizona</option>
									<option value="AR" >Arkansas</option>
									<option value="CA" >California</option>
									<option value="CO" >Colorado</option>
									<option value="CT" >Connecticut</option>
									<option value="DE" >Delaware</option>
									<option value="DC" >District of Columbia</option>
									<option value="FL" >Florida</option>
									<option value="GA" >Georgia</option>
									<option value="HI" >Hawaii</option>
									<option value="ID" >Idaho</option>
									<option value="IL" >Illinois</option>
									<option value="IN" >Indiana</option>
									<option value="IA" >Iowa</option>
									<option value="KS" >Kansas</option>
									<option value="KY" >Kentucky</option>
									<option value="LA" >Louisiana</option>
									<option value="ME" >Maine</option>
									<option value="MD" >Maryland</option>
									<option value="MA" >Massachusetts</option>
									<option value="MI" >Michigan</option>
									<option value="MN" >Minnesota</option>
									<option value="MS" >Mississippi</option>
									<option value="MO" >Missouri</option>
									<option value="MT" >Montana</option>
									<option value="NE" >Nebraska</option>
									<option value="NH" >New Hampshire</option>
									<option value="NV" >Nevada</option>
									<option value="NJ" >New Jersey</option>
									<option value="NM" >New Mexico</option>
									<option value="NY" >New York</option>
									<option value="NC" >North Carolina</option>
									<option value="ND" >North Dakota</option>
									<option value="OH" >Ohio</option>
									<option value="OK" >Oklahoma</option>
									<option value="OR" >Oregon</option>
									<option value="PA" >Pennsylvania</option>
									<option value="RI" >Rhode Island</option>
									<option value="SC" >South Carolina</option>
									<option value="SD" >South Dakota</option>
									<option value="TN" >Tennessee</option>
									<option value="TX" >Texas</option>
									<option value="UT" >Utah</option>
									<option value="VT" >Vermont</option>
									<option value="VA" >Virginia</option>
									<option value="WA" >Washington</option>
									<option value="WV" >West Virginia</option>
									<option value="WI" >Wisconsin</option>
									<option value="WY" >Wyoming</option>
						</select>
						<div ng-if="payment.contact.errors.state" id="payer-state-error" class="error">{{payment.contact.errors.state}}</div>
					</td> 
				</tr>
				<tr> <th> <div style="float:right; font-size: 12x;">
					<span ng-if="! payment.contact.country || payment.contact.country == 'UNITED STATES'" id="req-zip" class="required-indicator">*</span> 
					<label for="payer-zipcode">Zip Code:</label> </div></th>  
					<td class="requiredField"> 
						<input type="text" size=12 maxlength=12  id="payer-zipcode" name="payer-zipcode" ng-model="payment.contact.zipcode"> 
						<div ng-if="payment.contact.errors.zipcode" id="payer-zipcode-error" class="error">{{payment.contact.errors.zipcode}}</div>
					</td> 
				</tr>


				<!--
				<tr> <th> <div style="float:right; font-size: 12x;"><span id="req-phone" style="display:none;" class="required-indicator">*</span> 
					<label for="payer-phone-areacode">Phone&nbsp;Number:</label></div> </th>  
					<td class="optionalField">  
						<span id="us-phone" ng-if="payment.contact.country.length==0 || payment.contact.country == 'UNITED STATES'">
							<input type="text" size=3  maxlength=3   id="payer-phone-areacode" name="payer-phone-areacode" 
															ng-model="payment.contact.areacode" value="{{payment.contact.areacode}}"> &ndash;
							<input type="text" size=3  maxlength=3   id="payer-phone-prefix"   name="payer-phone-prefix"   
															ng-model="payment.contact.prefix" value="{{payment.contact.prefix}}"> &ndash;
							<input type="text" size=4  maxlength=4   id="payer-phone-line"     name="payer-phone-line"     
															ng-model="payment.contact.line" value="{{payment.contact.line}}"> --{{payment.contact.areacode}}-{{payment.contact.prefix}}-{{payment.contact.line}}--
						</span>
						<span id="nonus-phone" ng-if="payment.contact.country.length > 0 && payment.contact.country != 'UNITED STATES'">
							<input type="text" size=20 maxlength=20  id="payer-phone"   name="payer-phone"   
															ng-model="payment.contact.phone" value="{{payment.contact.phone}}">
						</span>
						<span id="payer-phone-error" class="errors" style="font-style: italic;">A valid phone number is required</span>
					</td> 
				</tr>
				-->

				<tr> <th style="padding-bottom: 15px;"> <div style="float:right; font-size: 12x;">
					<span ng-if="payment.options.require.phone" id="req-phone" class="required-indicator">*</span> 
					<label for="payer-phone">Phone&nbsp;Number:</label></div> </th>  
					<td class="optionalField">  
						<input type="text" size=20 maxlength=20  id="payer-phone"   name="payer-phone"   
														ng-model="payment.contact.phone" value="{{payment.contact.phone}}">
						<div ng-if="payment.contact.errors.phone" id="payer-phone-error" class="error">{{payment.contact.errors.phone}}</div>
					</td> 
				</tr>


				<tr> <th style="padding-bottom: 15px;"> 
					<div style="float:right; font-size: 12x;">	
						<span ng-if="payment.options.require.email" id="req-email" class="required-indicator">*</span> 
						<label for="payer-email">Email&nbsp;Address:</label> </div>
					</th>
					<td class="optionalField"> 
						<input type="text" size=26 maxlength=40 id="payer-email" name="payer-email" ng-model="payment.contact.email"> 
						<div ng-if="payment.contact.errors.email" id="payer-email-error" class="error">{{payment.contact.errors.email}}</div>
					</td> 
				</tr>
				<tr> <th style="padding-bottom: 25px;"> 
						<span ng-if="payment.options.require.email" id="req-vemail" class="required-indicator">*</span> 
						<label for="payer-vemail">Verify Your Email&nbsp;Address:</label>
					</th>
					<td class="optionalField"> 
						<input type="text" size=26 maxlength=40 id="payer-vemail" name="payer-vemail" ng-model="payment.contact.vemail"> 
						<div ng-if="payment.contact.errors.vemail" id="payer-vemail-error" class="error">{{payment.contact.errors.vemail}}</div>
					</td> 
				</tr>
				</table><div id="trace"></div>
		</div>
	</div><!-- end stop content -->
</div>