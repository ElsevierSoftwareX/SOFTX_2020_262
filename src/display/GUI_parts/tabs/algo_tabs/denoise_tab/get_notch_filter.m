function [h,w]=get_notch_filter(bandstops,f_vec)
h=ones(size(f_vec));

for ib=1:size(bandstops,1)
    h(f_vec>=bandstops(ib,1)&f_vec<=bandstops(ib,2))=0;
end
w=f_vec;
% if ~isempty(bandstops)
%     mbFilt = designfilt('arbmagfir','FilterOrder',60, ...
%         'Frequencies',f_vec-f_vec(1),'Amplitudes',amp_filt, ...
%         'SampleRate',2*f_vec(end));
%     [h,w] = freqz(mbFilt,numel(f_vec));
% else
%     mbFilt=[];
%     h=zeros(size(f_vec));
%     w=f_vec;
% end

end