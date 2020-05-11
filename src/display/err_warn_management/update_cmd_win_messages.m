function update_cmd_win_messages(src,evt,cmd_win,fid,max_lines)
% 
%  if feof(fid)
%      diary off; diary on;
%      %frewind(fid);
%      return;
%  end

nline=fgets(fid);

 if ~ischar(nline)
     diary off; diary on;
     return;
 end

cmd_win_txt=(get(cmd_win,'string'));

cmd_win_txt{length(cmd_win_txt),1}=nline;
cmd_win_txt=flipud(cmd_win_txt);
set(cmd_win,'string',flipud(cmd_win_txt(1:nanmin(length(cmd_win_txt),max_lines))));





