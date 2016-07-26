cluster 'test1' do
  prefix 'awsm'
  service 'alpine' do
    image 'alpine'
    command 'sh'
    args "-e", 'while true; do sleep 1; done'
  end
end
