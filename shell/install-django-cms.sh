# install django-cms
# you need root permission to do below steps
# assume you have installed pip

# install some python lib
echo "******************** install some python lib ********************"
apt-get install python-imaging

# install mysql-python
echo "******************** install mysql-python ********************"
pip install mysql-python

# install django-cms south
echo "******************** install django-cms south ********************"
pip install django-cms
pip install south
