angular.module('angularRails')
	.controller('NavCtrl', [
	'$scope',
	'$state',
	'Auth',
	function($scope,$state,Auth){

	 $(".nav a").on("click", function(){
	   $(".nav").find(".active").removeClass("active");
	    $(this).parent().addClass("active");
	 });

	 //$("#collapse1").collapse();	 	

	  $scope.signedIn = Auth.isAuthenticated;

	  $scope.isAdmin  = function(){
	  		if(Auth.isAuthenticated())
	  		{
	  			if($scope.user)
	  			{
	  				if($scope.user.admin)
	  				{
	  					return true;
	  				}
	  			}
	  		}
	  		return false;
	  };

	  $scope.logout = Auth.logout;

	  Auth.currentUser().then(function (user){
	    $scope.user = user;
	  });

	   $scope.$on('devise:new-registration', function (e, user){
	    $scope.user = user;
	    if($scope.user.admin)
	    {
	    	$state.go('main');
	    }else
	    {
	    	$state.go('home');
	    }
	  });

	  $scope.$on('devise:login', function (e, user){
	    $scope.user = user;
	    if($scope.user.admin)
	    {
	    	$state.go('main');
	    }else
	    {
	    	$state.go('home');
	    }
	  });

	  $scope.$on('devise:logout', function (e, user){
	    $scope.user = {};
	    $state.go('home');
	  });

	  $scope.$on('devise:new-session', function(event, currentUser) {
            // user logged in by Auth.login({...})
        });

      // Catch unauthorized requests and recover.
      $scope.$on('devise:unauthorized', function(event, xhr, deferred) {
        $state.go('home');    
    });


	}]);