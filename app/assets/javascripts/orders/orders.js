app = angular.module('angularRails');
app.factory('orders', ['$http',function($http){
   var o = {
    orders: []
  };

  o.getAll = function() {
    return $http.get('/orders.json',{ interceptAuth: true}).success(function(data){
      angular.copy(data, o.orders);
    });
  };

  o.get = function(id) {
    return $http.get('/orders/' + id + '.json').then(function(res){
      return res.data;
    });
  };

  return o;
}]);


app.controller('OrdersCtrl', [
'$scope',
'orders',
function($scope, orders){

	$scope.orders = orders.orders;

}]);