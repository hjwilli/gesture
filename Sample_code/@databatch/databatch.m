%=============================================================================
% databatch Data structure             
%=============================================================================  
% D=databatch(datadir)
% D=datbatch(D0);
% 
% Creates a data container given the directory name of a batch.
% Important: databatch is a handle, so if you copy it, you do not duplicate
% the data. To copy D0 to D don't do D=D0 do D=databatch(D0);

%==========================================================================
% Author of code: Isabelle Guyon -- isabelle@clopinet.com -- October 2011
%==========================================================================

classdef databatch < handle
	properties (SetAccess = public)
        datapath=[];
        dataname=[];
        current_movie=[];
        current_index=0;
        vocabulary_size=[];
        data_size=47; % This is a constant for these data
        subidx=[];
        invidx=[];
        Y={};
        n0=[];
        n1=[];
        n2=[];
        n3=[];
    end
    methods
        %%%%%%%%%%%%%%%%%%%
        %%% CONSTRUCTOR %%%
        %%%%%%%%%%%%%%%%%%%
        function this = databatch(datadir, truthdir) 
            if nargin<1, return; end
            if nargin<2, truthdir=[]; end
            if isa(datadir, 'databatch')
                D0=datadir;
                p=properties(D0);
                for k=1:length(p)
                    this.(p{k})=D0.(p{k});
                end
            else
                load(this, datadir, truthdir);
                % Check sanity
                sanity(this);
            end
        end
        
        function sanity(this)
            y=this.Y(1:this.vocabulary_size);
            if this.vocabulary_size ~= length(unique([y{:}]))
                error('Training examples do not span the vocabulary');
            end
            
            % Inventory the data files
            direc = dir([this.datapath this.dataname '/M*.avi']); Mfiles = {};
            [Mfiles{1:length(direc),1}] = deal(direc.name);
            if length(Mfiles)~=this.data_size
                error('Wrong number of M files');
            end
            
            direc = dir([this.datapath  this.dataname '/K*.avi']); Kfiles = {};
            [Kfiles{1:length(direc),1}] = deal(direc.name);
            if length(Kfiles)~=this.data_size
                error('Wrong number of M files');
            end
            
            N=this.data_size;
            M=zeros(1,N);
            for k=1:N
                fn=Mfiles{k};
                us=strfind(fn, '_');
                dt=strfind(fn, '.');
                M(k)=str2num(fn(us(end)+1:dt(1)-1));
            end
            if ~(all(sort(M) == 1:N))
                error('Incorrect M file numbering');
            end
            
            M=zeros(1,N);
            for k=1:N
                fn=Kfiles{k};
                us=strfind(fn, '_');
                dt=strfind(fn, '.');
                M(k)=str2num(fn(us(end)+1:dt(1)-1));
            end
            if ~(all(sort(M) == 1:N))
                error('Incorrect K file numbering');
            end
        end
        
        function load(this, datadir, truthdir)
            %this = load(this, datadir, truthdir)
            % Initialize a databatch object by loading the labels and the
            % first pattern.
            
            if nargin<2, truth_dir=[], end
            
            % Find the data path
            sl=union(strfind(datadir, '/'), strfind(datadir, '\'));
            if ~isempty(sl)
                this.dataname=datadir(sl(end)+1:end);
                this.datapath=datadir(1:sl(end));
            else
                this.dataname=datadir;
                this.datapath='';
            end

            % Load the training data
            tr=read_file([datadir '/' this.dataname '_train.csv']);
            this.vocabulary_size=length(tr);
            
            % Load the test data, if any
            tenum=this.data_size-this.vocabulary_size;
            te=cell(1,tenum);
            tef=[datadir '/' this.dataname '_test.csv'];
            if exist(tef, 'file')
                te=read_file(tef);
            elseif ~isempty(truthdir)
                tef=[truthdir '/' this.dataname '_test.csv'];
                te=read_file(tef);
            end
            this.Y=[tr,te]';
            this.subidx=1:length(this.Y);
            this.invidx=this.subidx;
            goto(this, 1);
        end            
        
        function goto(this, num)
            if num~=this.current_index && num>0 && num<=length(this)     
                num=this.subidx(num);
                this.current_movie.M=read_movie(sprintf('%s/%s/M_%d.avi',this.datapath, this.dataname, num));
                [this.current_movie.K, fps]=read_movie(sprintf('%s/%s/K_%d.avi',this.datapath, this.dataname, num));
                this.current_movie.fps=fps;
                this.current_index=num;
            end
        end
        
        function D = subset(this, idx)
            %D = subset(this, idx)
            % Select a data subset
            D=databatch(this); % Make a physical copy of this
            D.subidx=idx;
            D.invidx=[];
            D.invidx(idx)=1:length(idx);
        end 
        
        function X=get_X(this, num)
            %X=get_X(this, num)
            % There is no X matrix, but the current movie
            % can be considered X(num).
            % In the absence of argument, returns the current movie.
            if nargin<2
                num=this.current_index;
            end
            goto(this, num);
            X=this.current_movie;
        end
        
        function Y=get_Y(this, num)
            %Y=get_Y(this, num)
            % in the absence of argument, returns the whole Y
            % (not Y(current_index)).
            if nargin<2
                Y=this.Y(this.subidx);
            elseif isempty(num)
                Y=this.Y{this.current_index};
            else
                
                num=this.subidx(num);
                Y=this.Y{num};
            end
        end
        
        function next(this)
            %next(this)
            num=this.invidx(this.current_index)+1;
            if num>length(this)
                num=1;
            end
            goto(this, num);
        end     
        
        function prev(this)
            %prev(this)
            num=this.invidx(this.current_index)-1;
            if num<1
                num=length(this);
            end
            goto(this, num);
        end 
        
        function show(this, mode, h, R)
            %show(this, mode, h, R)
            % Show the current movie
            % Mode is either 'M' or 'K' for regular movie a Kinect depth
            % h is a figure handle
            % R is a recognizer
            if nargin<2
                mode='K';
            end
            if nargin<3
                h=figure;
            end
            if nargin<4,
                R=[];
            end
            
            % The true label
            y=get_Y(this, []);
            
            % Test the recognizer
            if ~isempty(R)
                te=test(R, subset(this, this.current_index));
                yte=get_X(te, 1);
                ttl=num2str(yte(1));
                for k=2:length(yte), ttl=[ttl '   ' num2str(yte(k))]; end
                if isempty(y)
                    col=[.7 .7 .7];
                elseif length(y)==length(yte) && all(y==yte)
                    col=[.4 .7 .5];
                else
                    col=[.7 .4 .5];
                end
                L=length(ttl);
                if isempty(this.n3) || ~ishandle(this.n3) || get(this.n3, 'Parent')~=h
                    this.n3=uicontrol('Parent', h, 'FontSize', 24, 'BackgroundColor', col, 'ForegroundColor', [0 0 0]);
                end
                set(this.n3, 'Position', [14*(18-L/2) 10 15+15*L 40], 'String', ttl);
            end
            
            % Display label
            if isempty(y), 
                ttl='Unknown labels';
            else
                ttl=num2str(y(1));
                for k=2:length(y), ttl=[ttl '   ' num2str(y(k))]; end
            end
            L=length(ttl);
            if isempty(this.n0) || ~ishandle(this.n0) || get(this.n0, 'Parent')~=h
                this.n0=uicontrol('Parent', h, 'FontSize', 24, 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [0 0 0]);
            end
            set(this.n0, 'Position', [14*(18-L/2) 50 15+15*L 40], 'String', ttl);
            
            % Display order number
            nstr=['[' num2str(num(this)) ']'];
            if isempty(this.n1) || ~ishandle(this.n1) || get(this.n1, 'Parent')~=h
                this.n1=uicontrol('Parent', h, 'Position', [10 300 60 40], 'FontSize', 24, 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [0 0 0]);
            end
            
            set(this.n1, 'String', nstr);
            % Display batch name
            ttl=this.dataname;
            L=length(ttl);
            if isempty(this.n2) || ~ishandle(this.n2) || get(this.n2, 'Parent')~=h
                this.n2=uicontrol('Parent', h, 'FontSize', 20, 'BackgroundColor', [0.4 0.4 0.4], 'ForegroundColor', [1 1 1]);
            end
            set(this.n2, 'Position', [14*(18-L/2) 360 15+15*L 40], 'String', ttl); 
            
            % Show movie
            if strcmp(mode, 'K')
                play_movie(this.current_movie.K, this.current_movie.fps, h);
            else
                play_movie(this.current_movie.M, this.current_movie.fps, h);
            end
        end
        
        function n=num(this)
            %n=num(this)
            n=this.current_index;
        end
        
        function n=length(this)
            %n=length(this)
            % number of samples
            n=length(this.subidx);
        end
        
       function n=labelnum(this)
            %n=labelnum(this)
            % number of labels (not of samples)
            Y=get_Y(this);
            n=0;
            for k=1:length(Y)
                n=n+length(Y{k});
            end
       end
        
       function delete(this)
           if ~isempty(this.n2) && ishandle(this.n2) 
               delete(this.n0);
               delete(this.n1);
               delete(this.n2);
               delete(this.n3);
           end
       end
            
    end %methods
end % classdef
