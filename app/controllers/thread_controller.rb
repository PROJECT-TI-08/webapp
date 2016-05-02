class ThreadController < ApplicationController


def test

Spawnling.new do
  logger.info("Inició...")
  sleep 11
  logger.info("Esperó 11 segundos y reanudó")
end

  respond_with true, json: true

end


end