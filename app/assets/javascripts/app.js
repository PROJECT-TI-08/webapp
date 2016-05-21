app = angular.module('angularRails',['ui.router','templates','Devise']);
app.config([
'$stateProvider',
'$urlRouterProvider',
'AuthInterceptProvider',
function($stateProvider, $urlRouterProvider,AuthInterceptProvider) {

  AuthInterceptProvider.interceptAuth(true);

  $stateProvider
  .state('main', {
      url: '/main',
      templateUrl: 'main/_main.html',
      controller: 'MainCtrl',
      onEnter: ['$state', 'Auth', function($state, Auth) {
        Auth.currentUser().then(function (user){
          if(!user.admin)
          {
            $state.go('home');
          }
        })
      }]
    })
    .state('home', {
      url: '/home',
      templateUrl: 'home/_home.html',
      controller: 'HomeCtrl',
      onEnter: ['$state', 'Auth', function($state, Auth) {
        Auth.currentUser().then(function (user){
          if(user.admin)
          {
            $state.go('main');
          }
        })
      }]
    })
    .state('products', {
    url: '/products',
    templateUrl: 'products/_products.html',
    controller: 'ProductsCtrl',
    resolve: {
          productPromise: ['products', function(products){
            return products.getAll();
          }]
        }
  }).state('orders', {
    url: '/orders',
    templateUrl: 'orders/_orders.html',
    controller: 'OrdersCtrl',
      resolve: {
          orderPromise: ['orders', function(orders){
            return orders.getAll();
          }]
        }
  }).state('stores', {
    url: '/stores',
    templateUrl: 'stores/_stores.html',
    controller: 'StoresCtrl',
    resolve: {
          storePromise: ['stores', function(stores){
            return stores.getAll();
          }]
        }
  }).state('login', {
      url: '/login',
      templateUrl: 'auth/_login.html',
      controller: 'AuthCtrl',
      onEnter: ['$state', 'Auth', function($state, Auth) {
        Auth.currentUser().then(function (){
         if(user.admin)
          {
            $state.go('main');
          }else
          {
            $state.go('home');
          }
        })
      }]
    })
    .state('register', {
      url: '/register',
      templateUrl: 'auth/_register.html',
      controller: 'AuthCtrl',
      onEnter: ['$state', 'Auth', function($state, Auth) {
        Auth.currentUser().then(function (){
          if(user.admin)
          {
            $state.go('main');
          }else
          {
            $state.go('home');
          }
        })
      }]
    });

  $urlRouterProvider.otherwise('/home');
}]);


