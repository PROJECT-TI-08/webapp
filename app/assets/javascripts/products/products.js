app = angular.module('angularRails');
app.factory('products', ['$http',function($http){
   var o = {
    products: []
  };

  o.getAll = function() {
    return $http.get('/products.json').success(function(data){
      angular.copy(data, o.products);
    });
  };

  o.get = function(id) {
    return $http.get('/products/' + id + '.json').then(function(res){
      return res.data;
    });
  };

  return o;
}]);


app.controller('ProductsCtrl', [
'$scope',
'products',
function($scope, products){

	$scope.products = products.products;

}]);