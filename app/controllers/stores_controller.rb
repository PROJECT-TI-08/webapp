class StoresController < ApplicationController
   before_filter :authenticate_user!

end
