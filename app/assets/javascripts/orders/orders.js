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
'$http',
function($scope, orders, $http){

	$scope.orders = orders.orders;

  $scope.get_ftp = function(){

  $http.get('/order_oc/get_ftp.json').then(function(res){
      console.log(res)
    });

  };


  $scope.get_oc = function(){

  $http.get('/order_oc/get_oc.json').then(function(res){
      console.log(res);
      $('#order_oc').html(res);
    });

  };



}]);