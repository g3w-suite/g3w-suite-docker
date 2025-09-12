# Customising G3W

## Login as admin
Go to your G3W instance, click Admin
![Click Admin](img/login_1.png)
Enter username and password
![Enter username and password](img/login_2.png)
Go to admin
![Go to admin](img/go_to_admin.png)

## Update Site Title
(1) Click Gear icon on the top right page
(2) Click Django administration
![](img/site_title_1.png)

(1) On Admin page, click Config
![](img/site_title_2.png)

Update website title (1) and (2) save
![](img/site_title_3.png)
Website title on the browser tab will be changed when reloaded, from
![](img/site_title_6.png)

to

![](img/site_title_5.png)

## Update Landing Page Background
(1) Click Gear icon on the top right page
(2) Click Files
![](img/custom_style_1.png)
Go to custom_static folder
![](img/custom_style_2.png)
Go to custom_static/images/home

(1) images.json contains the detail of the background image e.g. author and author URL.
(2) image to be used as background.
![](img/custom_style_3_update_landing_page.png)

If images.json is not provided, it will use any image (and select the first image) in the directory as background image.
![](img/custom_style_4_landing_page_author_info.png)

Example of updated images (updated to white image)
![](img/custom_style_5_landing_page_updated.png)


## Update logo
(1) Click Gear icon on the top right page
(2) Click Files
![](img/custom_style_1.png)
Replace these files with your desired logo. 
Follow the dimension of the files to ensure nice fit on the website UI.
Uploaded files must follow the exact same name.
![](img/custom_logo_1.png)

(1) favicon.ico will be shown as favicon on the browser tab.

![](img/custom_logo_2.png)

(2) logo_main.png will be used when left sidebar on the admin page is expanded.
![](img/custom_logo_3.png)

(3) logo_main.png will be used when left sidebar on the admin page is collapsed.
![](img/custom_logo_4.png)

(4) logo_login.png will be used when you login to the admin page directly e.g. from
https://your-g3w.geospatialhosting.com/en/login/?next=/en/admin/, instead of using landing page.
![](img/custom_logo_5.png)

## Customise Website Style and Colors

(1) Click Gear icon on the top right page
(2) Click Files
![](img/custom_style_1.png)

Go to custom_static/css.

Here, you will see 2 files: (1) custom.css and (2) style.css

You can edit custom.css and upload it (3).
![](img/custom_style_1_css.png)

If you need original version of those files, you can go to:
https://github.com/kartoza/g3w-admin/tree/GeoHosting/g3w-admin/core/static/custom_static/css