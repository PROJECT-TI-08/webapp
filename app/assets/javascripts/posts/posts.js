app = angular.module('angularRails');
app.factory('posts', ['$http',function($http){
   var o = {
    posts: []
  };

  o.getAll = function() {
    return $http.get('/posts.json').success(function(data){
      angular.copy(data, o.posts);
    });
  };

  o.create = function(post) {
  return $http.post('/posts.json', post).success(function(data){
    o.posts.push(data);
  });
};

o.upvote = function(post) {
  return $http.put('/posts/' + post.id + '/upvote.json')
    .success(function(data){
      post.upvotes += 1;
    });
};

o.get = function(id) {
  return $http.get('/posts/' + id + '.json').then(function(res){
    return res.data;
  });
};

o.addComment = function(id, comment) {
  return $http.post('/posts/' + id + '/comments.json', comment);
}

o.upvoteComment = function(post, comment) {
  return $http.put('/posts/' + post.id + '/comments/'+ comment.id + '/upvote.json')
    .success(function(data){
      comment.upvotes += 1;
    });
};

  return o;
}]);


app.controller('PostsCtrl', [
'$scope',
'posts',
'post',
function($scope, posts, post){

	$scope.post = post;

	$scope.incrementUpvotes = function(comment){
	  posts.upvoteComment(post, comment);
	};

	$scope.addComment = function(){
	  if($scope.body === '') { return; }
	  posts.addComment(post.id, {
	    body: $scope.body,
	    author: 'user',
	  }).success(function(comment) {
	    $scope.post.comments.push(comment);
	  });
	  $scope.body = '';
	};

}]);