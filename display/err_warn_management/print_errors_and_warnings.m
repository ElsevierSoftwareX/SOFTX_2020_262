function print_errors_and_warnings(fids,type,err)

switch type
    case 'warning'
        
        if ~ischar(err)
            arrayfun(@(x) fprintf(x,'%s: WARNING: %s\n',datestr(now,'HH:MM:SS'),err.message),fids,'un',0);
            warning(err.message);
        else
            arrayfun(@(x) fprintf(x,'%s: WARNING: %s\n',datestr(now,'HH:MM:SS'),err),fids,'un',0);
            warning(err);
            
        end
    case 'error'
        if ~ischar(err)
            warning(err.message);
            
            [~,f_temp,e_temp]=fileparts(err.stack(1).file);
            err_str=sprintf('file %s, line %d',[f_temp e_temp],err.stack(1).line);
            
            arrayfun(@(x) fprintf(x,'%s: ERROR: %s\n',datestr(now,'HH:MM:SS'),err_str),unique([1 fids]),'un',0);
            arrayfun(@(x) fprintf(x,'%s\n',err.message),fids,'un',0);
        else
            warning(err);
        end
    case 'log'
        arrayfun(@(x) fprintf(x,'%s: LOG: %s\n',datestr(now,'HH:MM:SS'),err),unique([1 fids]),'un',0);
    otherwise
        if ~isempty(fids)
            arrayfun(@(x) fprintf(x,'%s: %s\n',datestr(now,'HH:MM:SS'),err),unique(fids),'un',0);
        end
end
end