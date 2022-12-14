FROM ubuntu
RUN sudo apt-get update 
RUN sudo apt-get install apache2 -y
COPY index.html /var/www/html/
CMD ["apachectl","-D","FOREGROUND"]
EXPOSE 80 
