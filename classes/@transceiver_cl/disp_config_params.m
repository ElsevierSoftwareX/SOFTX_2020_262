function fig=disp_config_params(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(trans_obj) isa(trans_obj,'transceiver_cl'));
addParameter(p,'idx_ping',1,@isnumeric);
addParameter(p,'font','default',@ischar);

parse(p,trans_obj,varargin{:});

fig =new_echo_figure([],'Units','pixels','Position',[200 300 900 400],'Resize','off',...
    'Name',sprintf('Configuration/Parameters %s ping %d',trans_obj.Config.ChannelID,p.Results.idx_ping),...
    'Tag',sprintf('config_params%s',trans_obj.Config.ChannelID));

config_str=trans_obj.Config.config2str();

jLabel = javaObjectEDT('javax.swing.JLabel',config_str);
jLabel.setBackground(java.awt.Color(1,1,1));
jLabel.setFont(java.awt.Font(p.Results.font,java.awt.Font.PLAIN,12));
[~,~] = javacomponent(jLabel,[0,0,900,400],fig);

param_str=trans_obj.Params.param2str(p.Results.idx_ping);

jLabel = javaObjectEDT('javax.swing.JLabel',param_str);
jLabel.setBackground(java.awt.Color(1,1,1));
jLabel.setFont(java.awt.Font(p.Results.font,java.awt.Font.PLAIN,12));
[~,~] = javacomponent(jLabel,[500,0,300,400],fig);

end