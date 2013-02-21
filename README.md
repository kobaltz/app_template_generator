Rails Application Template Generator
======================

This tempalte allows you to quickly pick up and start programming with Ruby on Rails

    rails new testerapp -d mysql -b template.rb

You will be asked a few questions when using this Builder. These questions are used soley for the purpose of creating your development database, and setting the credentials for your production database.

    What was the name of your app again
    
    
    What is the development password
		
    
    What is the production password
		
    
    What is the production server
    
    
Conflicts
======================
You will be prompted a few times to overwrite a file. This is fine. Just hit enter and you'll be set


POST REQUIREMENTS
======================

After you have successfully ran the script, you will need to modify the file

    app/mailers/user_mailer.rb
    
and fix the reset url. you will want to change the server it is pointing to as well as the user.reset_password_token.
