angular.module('angularRails').controller('MainCtrl', ['$scope','posts', function($scope,posts){

	$scope.posts = posts.posts;

	$scope.incrementUpvotes = function(post) {
	  posts.upvote(post);
	};

	$scope.addPost = function(){
	  if(!$scope.title || $scope.title === '') { return; }
	  posts.create({
	    title: $scope.title,
	    link: $scope.link,
	  });
	  $scope.title = '';
	  $scope.link = '';
	};

}]);