function open_txt_file(f_out)

try
    [~,~]=system(sprintf('start notepad++ "%s"',f_out));
    return
catch
    disp('You should install Notepad++...');
end

try
    system(sprintf('start "%s"',f_out))
catch
    warndlg_perso([],'',sprintf('Could not open created script, but it has been saved here: %s',f_out));
end

end