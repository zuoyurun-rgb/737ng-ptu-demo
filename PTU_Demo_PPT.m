function out = PTU_Demo_PPT(mode)
%PTU_DEMO Boeing 737NG PTU interactive teaching schematic.
% Run: PTU_Demo_PPT
% Logic checks (no window): report = PTU_Demo_PPT('selftest')
% MATLAB R2023a; no additional toolbox required.
% Source: local textbook, printed pp.52-60 and 72-74, table 3-5.
% This is a qualitative teaching model, not an aircraft engineering simulator.
if nargin < 1, mode = 'demo'; end
if strcmpi(mode,'selftest'), out = selftest(); return; end
assert(strcmpi(mode,'demo'),'PTU_Demo_PPT:Mode','Use PTU_Demo_PPT or PTU_Demo_PPT(''selftest'').');

fontScale = 2.2;
bg = [0.965 0.977 0.99]; grey = [0.78 0.81 0.85];
col.A = [0.87 0.16 0.20]; col.B = [0.04 0.40 0.91];
col.S = [0.12 0.59 0.24]; col.R = [0.96 0.53 0.12];
col.M = [0.40 0.29 0.73];
fig = figure('Name','737NG PTU 大字截图版','NumberTitle','off', ...
    'Color',bg,'Position',[20 40 2200 1500],'MenuBar','none', ...
    'ToolBar','none','CloseRequestFcn',@closeDemo,'Tag','PTU_Demo_PPT');
out = fig;
ctrl = uipanel(fig,'Units','normalized','Position',[.02 .73 .96 .25], ...
    'BackgroundColor','white','BorderType','none');
lab(ctrl,[.015 .84 .08 .12],'选择模式',11,'bold');
modeSelect=uicontrol(ctrl,'Style','popupmenu', ...
    'String',{'模式一：预设工况','模式二：自定义工况'}, ...
    'Units','normalized','Position',[.10 .82 .25 .14], ...
    'FontSize',11*fontScale,'Callback',@changeMode,'Tag','modeSelect');
modeHint=lab(ctrl,[.38 .83 .60 .13], ...
    '模式一：选择七种预设，自定义条件已锁定。',10,'normal');
presets = {'① 正常供油','② B EDP 失压，B EMDP 正常', ...
    '③ PTU 接替供油','④ PTU 缺少驱动动力','⑤ PTU 被投入条件限制', ...
    '⑥ B EDP 单独供油','⑦ B EMDP 单独供油（地面）'};
lab(ctrl,[.015 .62 .075 .12],'预设工况',10,'normal');
preset = uicontrol(ctrl,'Style','popupmenu','String',presets, ...
    'Units','normalized','Position',[.09 .60 .36 .14], ...
    'FontSize',11*fontScale,'Callback',@applyPreset,'Tag','preset');
restrictionLabel = lab(ctrl,[.47 .62 .08 .12],'限制原因',10,'normal');
restriction = uicontrol(ctrl,'Style','popupmenu', ...
    'String',{'飞机在地面','后缘襟翼收上','后缘襟翼超过 10 单位'}, ...
    'Units','normalized','Position',[.55 .60 .18 .14], ...
    'FontSize',10*fontScale,'Callback',@applyPreset,'Tag','restriction','Visible','off');
set(restrictionLabel,'Visible','off');
pauseButton = uicontrol(ctrl,'Style','pushbutton','String','暂停动画', ...
    'Units','normalized','Position',[.75 .60 .10 .14], ...
    'FontSize',10*fontScale,'Callback',@togglePause,'Tag','pause');
uicontrol(ctrl,'Style','pushbutton','String','复位', ...
    'Units','normalized','Position',[.86 .60 .10 .14], ...
    'FontSize',10*fontScale,'Callback',@resetDemo,'Tag','reset');
lab(ctrl,[.75 .12 .08 .12],'动画速度',10,'normal');
speed = uicontrol(ctrl,'Style','popupmenu','String',{'慢','正常','快'}, ...
    'Value',2,'Units','normalized','Position',[.84 .10 .12 .14], ...
    'FontSize',10*fontScale,'Tag','speed');
demand = uicontrol(ctrl,'Style','checkbox','String','前缘装置动作需求', ...
    'Value',1,'Units','normalized','Position',[.75 .33 .23 .14], ...
    'BackgroundColor','white','FontSize',10*fontScale,'Callback',@changed,'Tag','demand');

customA=customPopup(.015,'A 系统',{'正常供压','失压'},'custom_A_pressure');
customBEdp=customPopup(.16,'B EDP',{'正常供压','失压'},'custom_B_EDP');
customBEmdp=customPopup(.305,'B EMDP',{'正常供压','不能供压'},'custom_B_EMDP');
customAir=customPopup(.45,'飞机状态',{'空中','地面'},'custom_air');
customFlap=customPopup(.595,'后缘襟翼', ...
    {'收上','1 单位','5 单位','10 单位','15 单位'},'custom_flap');
set(customFlap,'Value',3);
customControls=[customA customBEdp customBEmdp customAir customFlap demand];

air = readout(.015,'飞机','airborne');
flap = readout(.16,'后缘襟翼','flap');
aSource = readout(.305,'A 系统','aPressure');
bedp = readout(.45,'B EDP','bEdp');
bemdp = readout(.595,'B EMDP','bEmdp');

ax = axes(fig,'Units','normalized','Position',[.025 .025 .95 .69], ...
    'XLim',[0 100],'YLim',[0 48],'DataAspectRatio',[1 1 1]);
axis(ax,'off'); hold(ax,'on');
rectangle(ax,'Position',[1 1 38 46],'Curvature',.04,'EdgeColor',col.A, ...
    'LineStyle','--','FaceColor',[1 .965 .965]);
rectangle(ax,'Position',[60 1 39 46],'Curvature',.04,'EdgeColor',col.B, ...
    'LineStyle','--','FaceColor',[.945 .975 1]);
txt(20,45,'液压 A 系统',16,col.A,'bold');
txt(80,45,'液压 B 系统',16,col.B,'bold');

paths = struct('name',{},'xy',{},'kind',{},'line',{},'arrows',{},'length',{},'cum',{});
addPath('aEdpS',[10 38;10 32],'S');
addPath('aEmdpS',[20 38;20 32],'S');
addPath('aEdpP',[10 28;10 24;15 24],'A');
addPath('aEmdpP',[20 28;20 24;15 24],'A');
% One continuous downward animation, including the part hidden by the box.
% Separate short loops above/below the component can appear to run backwards.
addPath('aPressureThrough',[15 24;15 16],'A');
addPath('aOtherP',[15 16;12 16;12 8],'A');
addPath('aOtherR',[6 5.5;2.5 5.5;2.5 40;5 40],'R');
addPath('aFeed',[15 16;15 12;27 12],'A');
addPath('aMotor',[31 12;41 12],'A');
addPath('aReturn',[44 15;44 20;36 20;36 39;25 39],'R');
addPath('bEdpS',[79 38;79 36;69 36;69 32],'S');
addPath('bEmdpS',[85 38;85 32],'S');
addPath('bEdpP',[69 28;69 25;77 25],'B');
addPath('bEmdpP',[85 28;85 25;77 25],'B');
addPath('bPumpMerge',[77 25;77 22],'B');
% EMDP-only supply (case 2): use a continuous rounded left-to-down route.
% Keep the original junction for the already accepted normal-supply case.
emdpAngle=linspace(pi/2,pi,25)';
emdpBend=[78+cos(emdpAngle) 24+sin(emdpAngle)];
addPath('bEmdpTurn',[85 28;85 25;emdpBend;77 22],'B');
% Case 6 mirrors the smooth single-source turn, without altering cases 1-5.
edpAngle=linspace(pi/2,0,25)';
edpBend=[76+cos(edpAngle) 24+sin(edpAngle)];
addPath('bEdpTurn',[69 28;69 25;edpBend;77 22],'B');
addPath('bPtuS',[77 40;57 40;57 15],'S');
addPath('bPtuP',[60 12;65 12;69 12;78 12],'B');
addPath('bLeFeed',[78 12;84 12],'B');
% Rounded downward-to-right elbow. Normal-supply arrows traverse the whole
% route, rather than restarting at the vertical/horizontal join.
bendAngle=linspace(pi,3*pi/2,25)';
bend=[78+cos(bendAngle) 13+sin(bendAngle)];
addPath('bNormal',[77 18;bend;84 12],'B');
% The shared horizontal pipe has its own pressure colour. Keep only the
% vertical/elbow stroke here; its animation still continues to the load.
set(paths(end).line,'XData',[77;bend(:,1)],'YData',[18;bend(:,2)]);
addPath('bReturn',[94 12;97 12;97 40;89 40],'R');

box(5,38,20,5,'A 系统油箱',[1 .90 .90]);
box(75,38,16,5,'B 系统油箱',[.85 .93 1]);
pump(10,30,'EDP'); pump(20,30,'EMDP');
pump(69,30,'EDP'); pump(85,30,'EMDP');
box(4,18,22,4,'A 系统压力组件',[1 1 1]);
box(66,18,22,4,'B 系统压力组件',[1 1 1]);
otherLoadBox = box(5,2.5,14,5.5,'A 其他用户\n用油示意',[1 1 1]);
box(21,10.5,3,3,'~',[1 1 1]);
txt(27,7.1,'流量限制器',9,[.25 .25 .25],'normal');
valveBox = box(27,10.2,4,3.6,'',[1 1 1]);
valveSymbol = txt(29,12,'×',16,col.A,'bold');
valveText = txt(30,16.3,'控制阀：关闭',10,[.2 .2 .2],'bold');
plot(ax,[47 54],[12 12],'-','Color',col.M,'LineWidth',12);
motorCircle = rectangle(ax,'Position',[41 9 6 6],'Curvature',[1 1], ...
    'FaceColor',[1 .87 .86],'LineWidth',2.5);
pumpCircle = rectangle(ax,'Position',[54 9 6 6],'Curvature',[1 1], ...
    'FaceColor',[.79 .90 1],'LineWidth',2.5);
txt(44,12,'M',15,[.1 .1 .1],'bold'); txt(57,12,'P',15,[.1 .1 .1],'bold');
motorRotor = plot(ax,[42.4 45.6],[12 12],'-','Color',col.A,'LineWidth',2);
pumpRotor = plot(ax,[55.4 58.6],[12 12],'-','Color',col.B,'LineWidth',2);
txt(44,6.7,'液压马达',10,[.2 .2 .2],'bold');
txt(57,6.7,'液压泵',10,[.2 .2 .2],'bold');
txt(50.5,2.6,'机械轴传功，不传油',10,col.M,'bold');
box(63,10.6,2.7,2.8,'▷',[1 1 1]);
box(68,10.6,2.7,2.8,'滤',[1 1 1]);
txt(69.5,7.5,'单向阀 / 油滤',9,[.25 .25 .25],'normal');
loadBox = box(83,8.5,12,7,'前缘襟翼\n与缝翼',[1 1 1]);
sourceAText = txt(27,24.8,'A 压力可用',10,col.A,'normal');
sourceBText = txt(81,4.5,'B 常规压力可用',10,col.B,'normal');
stateText = txt(50,45,'PTU 未投入',15,[.25 .3 .4],'bold');
shaftText = txt(50,20,'机械传动待命',10,col.M,'normal');

% Preserve the accepted layer order in cases 1/2. With PTU-only supply,
% draw the inactive normal-supply elbow behind the active blue horizontal
% pipe so that its grey stroke cannot erase the pipe or its moving arrows.
normalLayerOrder=ax.Children;
normalPipeLine=paths(strcmp({paths.name},'bNormal')).line;
ptuPipeLine=paths(strcmp({paths.name},'bPtuP')).line;
ptuLayerOrder=normalLayerOrder(normalLayerOrder~=normalPipeLine);
ptuLayerIndex=find(ptuLayerOrder==ptuPipeLine,1);
ptuLayerOrder=[ptuLayerOrder(1:ptuLayerIndex);normalPipeLine; ...
    ptuLayerOrder(ptuLayerIndex+1:end)];

uicontrol(ctrl,'Style','pushbutton','String','导出 PNG', ...
    'Units','normalized','Position',[.77 .81 .105 .16], ...
    'FontSize',10*fontScale,'Callback',@exportDiagram,'Tag','exportPPT');
gifButton=uicontrol(ctrl,'Style','pushbutton','String','导出 GIF', ...
    'Units','normalized','Position',[.885 .81 .105 .16], ...
    'FontSize',10*fontScale,'Callback',@exportGif,'Tag','exportGIF');
set(modeHint,'Position',[.38 .82 .38 .16]);
paused = false; phase = 0; lowAge = 0; lastLow = false;
clockRef = tic; lastTime = 0; destroyed = false;
activeMode=1; customInitialized=false; customState=defaults();
tm = timer('ExecutionMode','fixedSpacing','Period',.06,'BusyMode','drop', ...
    'TimerFcn',@tick,'ErrorFcn',@timerError,'Name','PTU_Demo_PPT_Animation');
setappdata(fig,'PTUTimer',tm);
setappdata(fig,'PTUWriteGIF',@writeGif);
update(0); start(tm);

    function exportDiagram(~,~)
        [file,folder]=uiputfile('*.png','保存 PPT 高清原理图','PTU_PPT.png');
        if isequal(file,0), return; end
        wasPaused=paused; paused=true;
        cleanup=onCleanup(@()restorePause(wasPaused));
        drawnow;
        exportgraphics(ax,fullfile(folder,file),'Resolution',300,'BackgroundColor',bg);
    end
    function exportGif(~,~)
        [file,folder]=uiputfile('*.gif','导出当前工况的 10 秒循环动画','PTU_PPT.gif');
        if isequal(file,0), return; end
        try
            writeGif(fullfile(folder,file),200);
        catch err
            errordlg(err.message,'GIF 导出失败');
        end
    end
    function writeGif(filename,frameCount)
        % Record the diagram only. Fixed steps make playback independent of
        % rendering speed, and cleanup restores the interactive timeline.
        validateattributes(frameCount,{'numeric'},{'scalar','integer','positive'});
        savedPhase=phase; savedAge=lowAge; savedLastLow=lastLow;
        savedPaused=paused; wasRunning=strcmp(tm.Running,'on');
        stop(tm); paused=true;
        set(gifButton,'Enable','off','String','导出中');
        temporary=[tempname(fileparts(filename)) '.gif'];
        cleanup=onCleanup(@()restoreAfterGif(temporary,savedPhase,savedAge,savedLastLow,savedPaused,wasRunning));
        for frameIndex=1:frameCount
            if ~isgraphics(fig), error('导出期间窗口已关闭。'); end
            update(.05); drawnow nocallbacks;
            frame=getframe(ax);
            [indexed,map]=rgb2ind(frame.cdata,256,'nodither');
            if frameIndex==1
                imwrite(indexed,map,temporary,'gif','LoopCount',Inf,'DelayTime',.05);
            else
                imwrite(indexed,map,temporary,'gif','WriteMode','append','DelayTime',.05);
            end
        end
        movefile(temporary,filename,'f');
    end
    function restoreAfterGif(temporary,savedPhase,savedAge,savedLastLow,savedPaused,wasRunning)
            if exist(temporary,'file'), delete(temporary); end
            phase=savedPhase; lowAge=savedAge; lastLow=savedLastLow;
            paused=savedPaused;
            if isgraphics(fig)
                set(gifButton,'Enable','on','String','导出 GIF');
                update(0); lastTime=toc(clockRef);
                if wasRunning && isvalid(tm), start(tm); end
            end
        end
    function restorePause(value)
        paused=value;
    end
    function h = readout(x,label,tag)
        h = uicontrol(ctrl,'Style','text','String','', ...
            'Units','normalized','Position',[x .025 .14 .12], ...
            'FontSize',10*fontScale,'BackgroundColor','white', ...
            'HorizontalAlignment','left','Tag',tag);
        set(h,'UserData',label);
    end
    function h=customPopup(x,label,items,tag)
        lab(ctrl,[x .44 .13 .10],label,10,'normal');
        h=uicontrol(ctrl,'Style','popupmenu','String',items,'Value',1, ...
            'Units','normalized','Position',[x .27 .13 .14], ...
            'FontSize',10*fontScale,'Enable','off','Callback',@customChanged,'Tag',tag);
    end
    function h = lab(parent,pos,str,sz,weight)
        h = uicontrol(parent,'Style','text','Units','normalized','Position',pos, ...
            'String',str,'FontSize',sz*fontScale,'FontWeight',weight, ...
            'HorizontalAlignment','left','BackgroundColor','white');
    end
    function h = txt(x,y,str,sz,color,weight)
        h = text(ax,x,y,sprintf(str),'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','FontSize',sz*fontScale,'Color',color, ...
            'FontWeight',weight,'Interpreter','none');
    end
    function h = box(x,y,w,hgt,str,color)
        h = rectangle(ax,'Position',[x y w hgt],'Curvature',.08, ...
            'FaceColor',color,'EdgeColor',[.2 .24 .3],'LineWidth',2.2);
        if ~isempty(str), txt(x+w/2,y+hgt/2,str,11,[.12 .15 .2],'bold'); end
    end
    function pump(x,y,str)
        rectangle(ax,'Position',[x-3.5 y-3.1 7 6.2],'Curvature',[1 1], ...
            'FaceColor','white','LineWidth',2);
        txt(x,y,str,9,[.15 .15 .15],'bold');
    end
    function addPath(name,xy,kind)
        lengths = hypot(diff(xy(:,1)),diff(xy(:,2)));
        h = plot(ax,xy(:,1),xy(:,2),'-','Color',grey,'LineWidth',12, ...
            'Tag',['path_' name]);
        n = max(1,ceil(sum(lengths)/7)); arr = gobjects(1,n);
        for k=1:n
            arr(k)=text(ax,0,0,'>','Color','white','FontSize',16*fontScale, ...
                'FontWeight','bold','HorizontalAlignment','center', ...
                'VerticalAlignment','middle','Visible','off','Clipping','on', ...
                'Tag',['arrow_' name]);
        end
        paths(end+1)=struct('name',name,'xy',xy,'kind',kind,'line',h, ...
            'arrows',arr,'length',sum(lengths),'cum',[0;cumsum(lengths)]);
    end
    function s = inputs()
        if activeMode==1
            s=scenarioInputs(get(preset,'Value'),get(restriction,'Value'));
        else
            s=readCustomInputs();
        end
        s.lowAge = lowAge;
    end
    function s=readCustomInputs()
        s=defaults();
        s.a=get(customA,'Value')==1;
        s.edp=get(customBEdp,'Value')==1;
        s.emdp=get(customBEmdp,'Value')==1;
        s.air=get(customAir,'Value')==1;
        s.flap=get(customFlap,'Value');
        s.demand=logical(get(demand,'Value'));
    end
    function writeCustomControls(s)
        set(customA,'Value',1+~s.a);
        set(customBEdp,'Value',1+~s.edp);
        set(customBEmdp,'Value',1+~s.emdp);
        set(customAir,'Value',1+~s.air);
        set(customFlap,'Value',s.flap);
        set(demand,'Value',s.demand);
    end
    function changeMode(~,~)
        nextMode=get(modeSelect,'Value');
        if activeMode==2, customState=readCustomInputs(); end
        if nextMode==2
            if ~customInitialized
                customState=scenarioInputs(get(preset,'Value'),get(restriction,'Value'));
                customInitialized=true;
            end
            writeCustomControls(customState);
        end
        activeMode=nextMode;
        restartTimeline();
    end
    function customChanged(~,~)
        if activeMode~=2, return; end
        customState=readCustomInputs();
        restartTimeline();
    end
    function changed(~,~)
        if activeMode~=2, return; end
        customState=readCustomInputs();
        update(0);
    end
    function applyPreset(~,~)
        if activeMode~=1, return; end
        restartTimeline();
    end
    function restartTimeline()
        % Each new condition starts a fresh teaching timeline.
        lowAge=0; lastLow=false; phase=0; lastTime=toc(clockRef);
        update(0);
    end
    function resetDemo(~,~)
        if activeMode==1
            set(preset,'Value',1); set(restriction,'Value',1);
        else
            customState=defaults(); writeCustomControls(customState);
        end
        set(speed,'Value',2); paused=false;
        set(pauseButton,'String','暂停动画'); restartTimeline();
    end
    function togglePause(~,~)
        paused=~paused;
        if paused, set(pauseButton,'String','继续动画');
        else, set(pauseButton,'String','暂停动画'); end
    end
    function tick(~,~)
        if destroyed || ~isgraphics(fig), return; end
        now=toc(clockRef); dt=max(0,now-lastTime); lastTime=now;
        % Pause freezes the teaching clock, rotors and arrows together.
        if paused, dt=0; end
        update(dt); drawnow limitrate;
    end
    function update(dt)
        s=inputs(); low=~s.edp;
        if low
            if lastLow
                lowAge=lowAge+dt;
            else
                lowAge=0;
            end
        else
            lowAge=0;
        end
        lastLow=low;
        % Bound visual travel per frame to avoid apparent reversal of repeated
        % arrows if rendering is late. The low-pressure clock still uses dt.
        rates=[.5 1 1.8]; phase=phase+min(dt,.06)*9*rates(get(speed,'Value'));
        s.lowAge=lowAge; r=evaluate(s); setappdata(fig,'PTUState',r);
        setappdata(fig,'PTUInputs',s);
        setappdata(fig,'PTUMode',activeMode);
        set(preset,'Enable',choose(activeMode==1,'on','off'));
        set(restriction,'Enable',choose(activeMode==1,'on','off'));
        set(customControls,'Enable',choose(activeMode==2,'on','off'));
        if activeMode==1
            % Disabled conditions mirror the selected preset, never stale edits.
            writeCustomControls(s);
            set(customControls,'BackgroundColor',[.93 .93 .93]);
            set(preset,'BackgroundColor','white');
            set(modeHint,'String','模式一：七种预设可选；下方自定义条件已锁定。');
        else
            set(customControls,'BackgroundColor','white');
            set(preset,'BackgroundColor',[.93 .93 .93]);
            set(modeHint,'String',['模式二：预设已锁定；对应供油类别：' r.matchLabel]);
        end
        showRestriction=choose(activeMode==1 && get(preset,'Value')==5,'on','off');
        set(restriction,'Visible',showRestriction);
        set(restrictionLabel,'Visible',showRestriction);
        set(air,'String',['飞机：' choose(s.air,'空中','地面')]);
        flapNames={'收上','1 单位','5 单位','10 单位','15 单位'};
        set(flap,'String',['襟翼：' flapNames{s.flap}]);
        set(aSource,'String',['A 系统：' choose(s.a,'压力正常','失压')]);
        set(bedp,'String',['B EDP：' choose(s.edp,'正常','低压')]);
        set(bemdp,'String',['B EMDP：' choose(s.emdp,'正常','不供压')]);
        emdpOnly=~s.edp && s.emdp;
        edpOnly=s.edp && ~s.emdp;
        for j=1:numel(paths)
            p=paths(j); [available,flow]=pathState(p.name,s,r);
            showPath=true;
            if strcmp(p.name,'bEmdpTurn'), showPath=emdpOnly; end
            if strcmp(p.name,'bEdpTurn'), showPath=edpOnly; end
            if emdpOnly && ismember(p.name,{'bEmdpP','bPumpMerge'})
                showPath=false;
            end
            if edpOnly && ismember(p.name,{'bEdpP','bPumpMerge'})
                showPath=false;
            end
            % End the inactive EDP branch at the rounded path's inlet.
            if strcmp(p.name,'bEdpP')
                set(p.line,'XData',[69 69 77+double(emdpOnly)]);
            end
            if strcmp(p.name,'bEmdpP')
                set(p.line,'XData',[85 85 77-double(edpOnly)]);
            end
            set(p.line,'Visible',choose(showPath,'on','off'));
            flow=flow && showPath;
            color=grey; if available, color=col.(p.kind); end
            set(p.line,'Color',color);
            for k=1:numel(p.arrows)
                if ~flow, set(p.arrows(k),'Visible','off'); continue; end
                distance=mod(phase+(k-1)*p.length/numel(p.arrows),p.length);
                seg=find(p.cum<=distance,1,'last'); seg=min(seg,size(p.xy,1)-1);
                a=p.xy(seg,:); b=p.xy(seg+1,:);
                f=(distance-p.cum(seg))/(p.cum(seg+1)-p.cum(seg));
                xy=a+f*(b-a); angle=atan2d(b(2)-a(2),b(1)-a(1));
                set(p.arrows(k),'Position',[xy 0],'Rotation',angle,'Visible','on');
            end
        end
        if r.output && ~r.bNormal
            ax.Children=ptuLayerOrder;
        else
            ax.Children=normalLayerOrder;
        end
        if r.valve
            set(valveBox,'FaceColor',[.80 .96 .82]); set(valveSymbol,'String','→','Color',col.S);
            set(valveText,'String','控制阀：打开');
        else
            set(valveBox,'FaceColor',[1 .89 .87]); set(valveSymbol,'String','×','Color',col.A);
            set(valveText,'String','控制阀：关闭');
        end
        theta=phase*.5;
        if r.motor, rotor(motorRotor,44,theta); else, rotor(motorRotor,44,0); end
        if r.driven, rotor(pumpRotor,57,theta); else, rotor(pumpRotor,57,0); end
        set(motorCircle,'EdgeColor',choose(r.motor,col.A,grey));
        set(pumpCircle,'EdgeColor',choose(r.output,col.B,grey));
        set(loadBox,'FaceColor',choose(r.leAvailable,[.80 .95 .85],[.93 .93 .93]));
        set(otherLoadBox,'FaceColor',choose(s.a,[.80 .95 .85],[.93 .93 .93]));
        set(sourceAText,'String',choose(s.a,'A 压力可用','A 系统失压'));
        set(sourceBText,'String',choose(r.bNormal,'B 常规压力可用','B 常规供压不可用'));
        set(stateText,'String',r.title,'Color',choose(r.output,col.S,[.35 .36 .4]));
        set(shaftText,'String',choose(r.driven,'机械轴正在转动','机械传动待命'));
        if s.fault==3 && r.motor, set(shaftText,'String','轴故障：马达转，泵不转'); end
    end
    function rotor(h,x,theta)
        dx=1.6*cos(theta); dy=1.6*sin(theta);
        set(h,'XData',[x-dx x+dx],'YData',[12-dy 12+dy]);
    end
    function timerError(~,event)
        warning('PTU_Demo_PPT:Timer','Animation timer stopped; diagnostic follows.');
        disp(event.Data);
    end
    function closeDemo(~,~)
        destroyed=true;
        if exist('tm','var') && ~isempty(tm) && isvalid(tm), stop(tm); delete(tm); end
        if isgraphics(fig), delete(fig); end
    end
end

function s=defaults()
s=struct('air',true,'flap',3,'a',true,'edp',true,'emdp',true, ...
    'demand',true,'aOtherDemand',true,'fault',1,'lowAge',0);
end

function s=scenarioInputs(caseId,restrictionId)
% Seven agreed cases. All retain sufficient B oil and healthy PTU hardware.
s=defaults();
switch caseId
    case 1 % Normal B supply; no PTU trigger.
    case 2 % B EMDP still provides normal pressure; PTU also qualifies.
        s.edp=false;
    case 3 % PTU powers the leading-edge branch.
        s.edp=false; s.emdp=false;
    case 4 % Case 3 without the A-side driving source.
        s.edp=false; s.emdp=false; s.a=false;
    case 5 % Change just one permission condition relative to case 3.
        s.edp=false; s.emdp=false;
        switch restrictionId
            case 1, s.air=false;
            case 2, s.flap=1;
            case 3, s.flap=5;
            otherwise, error('PTU_Demo_PPT:Restriction','Invalid restriction.');
        end
    case 6 % EDP normal; EMDP unavailable. No EDP-low trigger for PTU.
        s.emdp=false;
    case 7 % EMDP normal; EDP unavailable. Ground inhibits PTU operation.
        s.edp=false; s.air=false;
    otherwise, error('PTU_Demo_PPT:Case','Invalid teaching case.');
end
end

function r=evaluate(s)
% Flap indices: 1=retracted; 2/3/4=1/5/10 units; 5=outside range.
r.auto=s.air && s.flap>=2 && s.flap<=4 && s.a && ~s.edp && s.lowAge>.5;
r.inhibit=s.fault==5;
r.request=r.auto && ~r.inhibit;
% V1 teaching assumption: healthy valve follows request without travel time.
% Pressure recovery cancels request in this demo; exact aircraft reset logic
% is not established by local table 3-5. No latch/failure-to-power model.
r.valve=r.request && s.fault~=2;
r.motor=r.valve && s.a;
r.driven=r.motor && s.fault~=3;
r.output=r.driven && s.fault~=4;
r.bNormal=s.edp || s.emdp;
r.leAvailable=r.bNormal || r.output;
r.loadFlow=r.leAvailable && s.demand;
r.aOtherFlow=s.a && s.aOtherDemand;
r.matchedCase=classifyPreset(s);
matchLabels={'① B 两泵供油','② B EMDP + PTU', ...
    '③ PTU 接替供油','④ A 无驱动动力','⑤ PTU 被条件限制', ...
    '⑥ B EDP 单独供油','⑦ B EMDP 单独供油'};
r.matchLabel=matchLabels{r.matchedCase};
if r.output && r.bNormal
    r.supply='B EMDP 与 PTU 均有供压能力（不确定流量分担）';
elseif r.output
    r.supply='PTU（A 侧提供机械驱动功率，B 油箱提供油液）';
elseif s.edp && s.emdp
    r.supply='B EDP 与 B EMDP（不确定两泵流量分担）';
elseif s.emdp
    r.supply='B EMDP';
elseif s.edp
    r.supply='B EDP';
else
    r.supply='无可用的前缘正常液压供压源';
end
reasons={};
if ~s.air, reasons{end+1}='地面禁止'; end
if s.flap==1, reasons{end+1}='后缘襟翼已收上'; end
if s.flap==5, reasons{end+1}='后缘襟翼超过 10 单位'; end
if ~s.a, reasons{end+1}='A 系统无可用驱动压力'; end
if s.edp, reasons{end+1}='B EDP 正常，无低压触发';
elseif s.lowAge<=.5, reasons{end+1}=sprintf('等待低压持续超过 0.5 s（当前 %.2f s）',s.lowAge); end
if r.inhibit, reasons{end+1}='备用襟翼 ARM + DOWN 禁止'; end
if r.request && s.fault==2, reasons{end+1}='已有开阀请求，但控制阀卡关'; end
if r.valve && s.fault==3, reasons{end+1}='阀已打开，但机械轴故障，泵不能被驱动'; end
if r.driven && s.fault==4, reasons{end+1}='泵轴转动，但 PTU 无油可吸，不能有效供压'; end
if r.output
    r.title='PTU 已投入 · 液压输出可用';
    reasons{end+1}='A 油驱动马达，机械轴带动泵；泵吸取 B 油并向前缘支路供压';
elseif r.request
    r.title='PTU 有投入请求 · 输出不可用';
else
    r.title='PTU 未投入';
end
r.reason=strjoin(reasons,'；');
if ~s.demand
    r.flowNote='无前缘动作需求：停止作动器工作流箭头；PTU 内部无负载流动未建模。';
elseif ~r.leAvailable
    r.flowNote='前缘正常液压动力不可用；本窗口不模拟备用液压系统。';
elseif r.output && r.bNormal
    r.flowNote='EMDP 与 PTU 两路供油方向示意：均从 B 油箱取油，汇合后到前缘装置；箭头不代表实际流量分担。';
elseif r.output
    r.flowNote='前缘动作示意：B 油箱 → PTU 泵 → 单向阀 / 油滤 → 前缘装置 → B 油箱。';
elseif s.edp && ~s.emdp
    r.flowNote='B EDP 单独供油：B 油箱 → EDP → 压力组件 → 前缘装置 → B 油箱；EMDP、PTU 支路待命。';
elseif ~s.edp && s.emdp && ~s.air
    r.flowNote='B EMDP 单独供油；飞机在地面，PTU 禁止自动投入；不保证前缘装置的正常动作速率。';
elseif ~s.edp && s.emdp && (~s.a || s.flap==1 || s.flap==5)
    r.flowNote='B EMDP 单独供油；PTU 未满足驱动或投入条件；不保证前缘装置的正常动作速率。';
else
    r.flowNote='前缘由 B 常规泵源供压；两台泵同时可用时不计算各自承担的流量。';
end
end

function id=classifyPreset(s)
% Supply category, not an exact copy of every setting in a preset.
% Delay is evaluated separately, so the category does not jump during startup.
eligible=s.a && s.air && s.flap>=2 && s.flap<=4;
if s.edp
    id=choose(s.emdp,1,6);
elseif s.emdp
    id=choose(eligible,2,7);
elseif ~s.a
    id=4;
elseif eligible
    id=3;
else
    id=5;
end
end

function [available,flow]=pathState(name,s,r)
% Availability is distinct from an indicated working flow.
available=false; flow=false;
switch name
    case {'aEdpS','aEdpP','aEmdpS','aEmdpP','aPressureThrough'}
        available=s.a;
        % Qualitative source directions, not individual pump flow shares.
        flow=r.aOtherFlow || (r.motor && s.demand);
    case {'aOtherP','aOtherR'}
        available=s.a; flow=r.aOtherFlow;
    case 'aFeed'
        available=s.a; flow=r.motor && s.demand;
    case 'aMotor'
        available=r.motor; flow=r.motor && s.demand;
    case 'aReturn'
        available=r.motor; flow=r.motor && s.demand;
    case {'bEdpS','bEdpP'}
        available=s.edp; flow=s.edp && r.loadFlow && ~r.output;
    case {'bEmdpS','bEmdpP'}
        available=s.emdp; flow=s.emdp && r.loadFlow;
    case 'bEmdpTurn'
        available=s.emdp && ~s.edp; flow=available && r.loadFlow;
    case 'bEdpTurn'
        available=s.edp && ~s.emdp; flow=available && r.loadFlow;
    case {'bPumpMerge','bNormal'}
        available=r.bNormal; flow=r.bNormal && r.loadFlow;
    case 'bPtuS'
        flow=r.output && s.demand;
        % Suction uses green only while the displayed working flow is active.
        % Grey in standby does not imply a closed or disconnected oil line.
        available=flow;
    case 'bPtuP'
        available=r.output; flow=r.output && s.demand;
    case 'bLeFeed'
        available=r.leAvailable;
        % With normal supply, bNormal already animates this shared segment.
        flow=r.loadFlow && ~r.bNormal;
    case 'bReturn'
        available=r.leAvailable; flow=r.loadFlow;
end
end

function y=choose(condition,a,b)
if condition, y=a; else, y=b; end
end

function report=selftest()
for k=1:7
    q=scenarioInputs(k,1); q.lowAge=.6; r=evaluate(q);
    assert(q.fault==1 && q.demand);
    switch k
        case 1, assert(~r.auto && ~r.valve && r.bNormal && r.leAvailable);
        case 2, assert(r.auto && r.output && ~q.edp && q.emdp && r.bNormal);
        case 3, assert(r.output && ~r.bNormal && r.leAvailable);
        case 4, assert(~q.a && ~r.output && ~r.leAvailable);
        case 5, assert(~r.auto && ~r.valve && ~r.leAvailable);
        case 6, assert(q.air && q.edp && ~q.emdp && ~r.auto && ~r.output && r.leAvailable);
        case 7, assert(~q.air && ~q.edp && q.emdp && ~r.auto && ~r.output && r.leAvailable);
    end
    assert(r.matchedCase==k);
end
% Single-pump presets must not animate the other pump or either PTU branch.
for k=6:7
    q=scenarioInputs(k,1); q.lowAge=1; r=evaluate(q);
    if k==6
        active={'bEdpS','bEdpTurn','bNormal','bReturn'};
        inactive={'bEmdpS','bEmdpP','bEmdpTurn','bPtuS','bPtuP'};
    else
        active={'bEmdpS','bEmdpTurn','bNormal','bReturn'};
        inactive={'bEdpS','bEdpP','bEdpTurn','bPtuS','bPtuP'};
    end
    for j=1:numel(active)
        [a,f]=pathState(active{j},q,r); assert(a && f);
    end
    for j=1:numel(inactive)
        [a,f]=pathState(inactive{j},q,r); assert(~a && ~f);
    end
    q.demand=false; r=evaluate(q);
    for j=1:numel(active)
        [a,f]=pathState(active{j},q,r); assert(a && ~f);
    end
end
for k=1:3
    q=scenarioInputs(5,k); q.lowAge=.6; r=evaluate(q);
    assert(q.a && ~q.edp && ~q.emdp && ~r.auto && ~r.valve);
    assert(sum([~q.air q.flap==1 q.flap==5])==1);
end
s=defaults(); r=evaluate(s); assert(~r.auto && ~r.valve && r.bNormal);
% Normal supply: both source branches and the common LE feed are animated.
normalPaths={'bEdpS','bEmdpS','bEdpP','bEmdpP','bPumpMerge','bNormal'};
for j=1:numel(normalPaths)
    [a,f]=pathState(normalPaths{j},s,r); assert(a && f);
end
[a,f]=pathState('bPtuP',s,r); assert(~a && ~f);
[a,f]=pathState('bLeFeed',s,r); assert(a && ~f); % animated by bNormal
[a,f]=pathState('bPtuS',s,r); assert(~a && ~f);
aPaths={'aEdpS','aEmdpS','aEdpP','aEmdpP','aPressureThrough','aOtherP','aOtherR'};
for j=1:numel(aPaths)
    [a,f]=pathState(aPaths{j},s,r); assert(a && f);
end
[a,f]=pathState('aFeed',s,r); assert(a && ~f);
[a,f]=pathState('aMotor',s,r); assert(~a && ~f);
q=s; q.a=false; r=evaluate(q);
for j=1:numel(aPaths)
    [a,f]=pathState(aPaths{j},q,r); assert(~a && ~f);
end
q=s; q.demand=false; r=evaluate(q);
for j=1:numel(normalPaths)
    [a,f]=pathState(normalPaths{j},q,r); assert(a && ~f);
end
s.edp=false; s.emdp=false; s.lowAge=.6;
r=evaluate(s); assert(r.auto && r.valve && r.output && r.loadFlow);
for t=[0 .3 .5]
    q=s; q.lowAge=t; r=evaluate(q); assert(~r.auto && ~r.valve);
end
q=s; q.air=false; r=evaluate(q); assert(~r.auto && ~r.valve);
for f=[1 5]
    q=s; q.flap=f; r=evaluate(q); assert(~r.auto);
end
q=s; q.a=false; r=evaluate(q); assert(~r.valve && ~r.output);
q=s; q.fault=2; r=evaluate(q); assert(r.request && ~r.valve && ~r.output);
q=s; q.fault=3; r=evaluate(q); assert(r.motor && ~r.driven && ~r.output);
q=s; q.fault=4; r=evaluate(q); assert(r.driven && ~r.output);
q=s; q.fault=5; r=evaluate(q); assert(r.auto && r.inhibit && ~r.valve);
q=s; q.emdp=true; r=evaluate(q); assert(r.auto && r.bNormal && r.leAvailable);
case2Paths={'bEmdpS','bEmdpP','bPumpMerge','bNormal','bPtuS','bPtuP','bReturn'};
for j=1:numel(case2Paths)
    [a,f]=pathState(case2Paths{j},q,r); assert(a && f);
end
[a,f]=pathState('bEdpP',q,r); assert(~a && ~f);
[a,f]=pathState('bLeFeed',q,r); assert(a && ~f); % bNormal owns shared arrows
q=s; q.demand=false; r=evaluate(q); assert(r.output && ~r.loadFlow);
[a,f]=pathState('bPtuP',q,r); assert(a && ~f);
q=s; q.edp=true; r=evaluate(q); assert(~r.valve && ~r.output);
% All 80 custom system settings, each with/without LE motion demand.
customCount=0;
for aState=0:1
    for bMask=0:3
        for airborne=0:1
            for flapIndex=1:5
                for motion=0:1
                    q=defaults();
                    q.a=logical(aState);
                    q.edp=logical(bitget(bMask,1));
                    q.emdp=logical(bitget(bMask,2));
                    q.air=logical(airborne); q.flap=flapIndex;
                    q.demand=logical(motion); q.lowAge=1;
                    r=evaluate(q);
                    expectedPtu=q.a && ~q.edp && q.air && ismember(q.flap,[2 3 4]);
                    assert(r.output==expectedPtu);
                    assert(r.leAvailable==(q.edp || q.emdp || expectedPtu));
                    assert(r.loadFlow==(r.leAvailable && q.demand));
                    [a,f]=pathState('aEdpP',q,r);
                    assert(a==q.a && (~f || q.a));
                    [a,f]=pathState('aEmdpP',q,r);
                    assert(a==q.a && (~f || q.a));
                    assert(r.matchedCase>=1 && r.matchedCase<=7);
                    customCount=customCount+1;
                end
            end
        end
    end
end
report=struct('passed',true,'customCombinationsChecked',customCount, ...
    'description','Seven presets, three restrictions and 160 aggregate-A custom combinations passed.');
disp(report);
end






