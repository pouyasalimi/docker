# Docker
برای اجرا ابندا داکر و داکر کامپوز رو نصب کنید
اطلاعات بیشتر: https://docs.docker.com/compose/install/

بعد از نصب داکر از طریق دستورات زیر می تونید برنامه رو اجرا کنید:
(فرض می کنیم که کامند ها رو از روت پروژه اجرا می کنید)

اجرای پروژه:

`./docker/app up -d`

اجرای کامند های لاراول در کانتینر اپ:

`./docker/app php artisan`

`./docker/app composer dump-autoload`

اجرای کامند لاین ماریا:

`./docker/app mariadb`

اجرای بش در کانتینیر اپ لاراول:

`./docker/app bash`

لینک کردن استوریج:

`./docker/app php artisan storage:link`
