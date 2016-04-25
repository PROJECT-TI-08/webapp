app = angular.module('angularRails');
app.factory('stores', ['$http',function($http){
   var o = {
    stores: []
  };

  o.getAll = function() {
    return $http.get('/stores.json').success(function(data){
      angular.copy(data, o.stores);
    });
  };

  o.get = function(id) {
    return $http.get('/stores/' + id + '.json').then(function(res){
      return res.data;
    });
  };

  return o;
}]);


app.controller('StoresCtrl', [
'$scope',
'stores',
function($scope, stores){

	$scope.stores = stores.stores;

}]);