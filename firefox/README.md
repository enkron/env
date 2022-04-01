# "Tree Style Tab" Firefox extension
After installing the extension it'd be a good idea to hide a firefox's native tab bar from the top of a window.
1) check 'about:config' in a browser's search tab and change the value
   of `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`;
2) go to menu -> Help -> More troubleshooting information -> Profile Folder, to find an user profile path;
3) create a directory called `chrome` if not exists;
4) put the `userChrome.css` file under the `chrome` path;
5) restart Firefox.
