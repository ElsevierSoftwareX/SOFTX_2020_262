function params=read_params_xstruct(xstruct)

Channels=xstruct.Parameter.Channel;
for i=1:length(Channels)
    if length(Channels)>1
        Channel=Channels{i};
    else
        Channel=Channels;
    end
    params_temp=Channel.Attributes;
    
    params = structfun(@read_params,params_temp,'un',0);
    
end
end
function y=read_params(x)
val_temp=str2double(x);
if ~isnan(val_temp)
    y=val_temp;
else
    y=x;
end
end