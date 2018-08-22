<div class="owner">
    <div ng-if="clientURL">
        <a href="{{clientURL}}showdetail2.jsp?can={{account.account}}"> {{account.account}} </a>
    </div>
    <div ng-if="!clientURL">
        {{account.account}} <br>
    </div>
    <div ng-if="account.ownerAddress" ng-bind-html="renderHtml(account.ownerAddress)"> </div>
    <div ng-if="!account.ownerAddress">
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
</div>
