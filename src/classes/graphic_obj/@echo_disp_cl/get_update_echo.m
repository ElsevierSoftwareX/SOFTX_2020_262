function update_echo=get_update_echo(echo_obj,lay_Unique_ID,lay_CID,fieldname,idx_r_disp,idx_p_disp,dr,dp)

update_echo=0;
if ~isempty(echo_obj.echo_usrdata.Layer_ID)&&~isempty(echo_obj.echo_usrdata.Idx_r)
   if ~(idx_r_disp(1)>=echo_obj.echo_usrdata.Idx_r(1)&&idx_r_disp(end)<=echo_obj.echo_usrdata.Idx_r(end))||...
            ~(idx_p_disp(1)>=echo_obj.echo_usrdata.Idx_pings(1)&&idx_p_disp(end)<=echo_obj.echo_usrdata.Idx_pings(end))||...
            dr~=round(nanmean(diff(echo_obj.echo_usrdata.Idx_r)))|| dp~=round(nanmean(diff(echo_obj.echo_usrdata.Idx_pings)))||...
            ~strcmpi(echo_obj.echo_usrdata.CID,lay_CID)||...
            ~strcmpi(lay_Unique_ID,echo_obj.echo_usrdata.Layer_ID)||...
            ~strcmpi(fieldname,echo_obj.echo_usrdata.Fieldname)
        update_echo=1;
    end
else
    update_echo=1;
end