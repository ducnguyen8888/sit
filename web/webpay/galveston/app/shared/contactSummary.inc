<div>
    <table class="payment-metadata" border=0>
    <tr> <th> Name: </th> <td> {{payment.contact.name}} </td> </tr>
    <tr> <th> Address: </th> <td> {{payment.contact.street}} </td> </tr>
    <tr> <th> City: </th> <td> {{payment.contact.city}} </td> </tr>

    <tr ng-if="payment.contact.state.length > 0"> <th> State: </th> <td> {{payment.contact.state}} </td> </tr>
    <tr ng-if="payment.contact.zipcode.length > 0"> <th> Zip Code: </th> <td> {{payment.contact.zipcode}} </td> </tr>
    <tr ng-if="payment.contact.country.length > 0"> <th> Country: </th> 
        <td> <div ng-if="payment.contact.country.length == 0">United States</div>
            <div ng-if="payment.contact.country.length > 0">{{payment.contact.country}}</div>
        </td> 
    </tr>

    <tr> <td>&nbsp;</td></tr>
    <tr ng-if="payment.contact.email.length > 0"> <th> Email&nbsp;Address: </th> <td> {{payment.contact.email}} </td> </tr>
    <tr ng-if="payment.contact.phone.length > 0"> <th> Phone&nbsp;Number: </th> <td> {{payment.contact.phone}} </td> </tr>
    <tr> <td style="height:4px;line-height:4px;">&nbsp;</td></tr>

    </table>
</div>