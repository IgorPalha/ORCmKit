function out = HEX_profile_2(fluid_h, m_dot_h, P_h, in_h, fluid_c, m_dot_c, P_c, in_c, Q_dot, param)
%% CODE DESCRIPTION
% ORCmKit - an open-source modelling library for ORC systems

% Remi Dickes - 27/04/2016 (University of Liege, Thermodynamics Laboratory)
% rdickes @ulg.ac.be
%
% HEX_profile is a single matlab code aiming to calculate the temperature
% profiles occuring between two media if the heat power is provided as
% input. This code has been developed to be as general as possible and can
% be used for multi-phase heat transfer for both hot and cold fluids and can 
% also handle incompressible medium. The code implements in an automatic algorithm the 
% cells division methodology proposed by Bell et al. in
%
% "A generalized moving-boundary algorithm to predict the heat transfer rate 
% of counterflow heat exchangers for any phase configuration,� 
% Appl. Therm. Eng., vol. 79, pp. 192�201, 2015. 
%
% The model inputs are:
%       - fluid_h: nature of the hot fluid                        	[-]
%       - P_h: pressure of the hot fluid                   [Pa]
%       - in_h: supply temperature or enthalpy of the hot fluid   [K or J/kg]
%       - m_dot_h: mass flow rate of the hot fluid                  [kg/s]
%       - fluid_c: nature of the cold fluid                        	[-]
%       - P_c: pressure of the cold fluid                  [Pa]
%       - in_c: supply temperature or enthalpy of the cold fluid  [K or J/kg]
%       - m_dot_c: mass flow rate of the cold fluid                 [kg/s]
%       - Q_dot: heat power transferred between the fluids          [W]
%       - param: structure variable containing the model parameters i.e.
%           *param.type_h = type of input for hot fluid ('H' for enthalpy,'T' for temperature)
%           *param.type_c = type of input for cold fluid ('H' for enthalpy,'T' for temperature)

% The model outputs are:
%       - out: a structure variable which includes at miniumum the following information:
%               - x_vec =  vector of power fraction in each zone
%               - Qdot_vec =  vector of heat power in each zone [W]
%               - H_h_vec = HF enthalpy vector                  [J/kg]
%               - H_c_vec = CF enthalpy vector                  [J/kg]
%               - T_h_vec = HF temperature vector               [K]
%               - T_c_vec = CF temperature vector               [K]
%               - DT_vec = Temperature difference vector        [K]
%          	
% See the documentation for further details or contact rdickes@ulg.ac.be

%% MODELLING CODE
decim = 3; % degree of accuracy used for comparing the entalpies

if strcmp(param.type_h,'H') && strcmp(param.type_c,'H')  %% CASE 1 : HOT FLUID AND COLD FLUID MIGHT EXPERIENCE A PHASE CHANGE
    % Cell division for hot fluid (create a vector of enthalpy the different zones on the hot fluid side)
    if strcmp(param.port_h,'su')
        h_h_su = in_h;
        h_h_ex = h_h_su - Q_dot/m_dot_h;
    elseif strcmp(param.port_h,'ex')
        h_h_ex = in_h;
        h_h_su = h_h_ex + Q_dot/m_dot_h;
    end
    if not(isempty(strfind(fluid_h, 'INCOMP:')))
        h_h_l = h_h_su*3;
        h_h_v = h_h_su*3;
    else
        h_h_l = CoolProp.PropsSI('H','P',P_h,'Q',0, fluid_h);
        h_h_v = CoolProp.PropsSI('H','P',P_h,'Q',1, fluid_h);
    end 
    if round(h_h_v,decim) < round(h_h_ex,decim) 
        H_h_vec = [h_h_ex  h_h_su]; %if vapour-phase only
    elseif round(h_h_l,decim) > round(h_h_su,decim)
        H_h_vec = [h_h_ex  h_h_su]; % if liquid-phase only
    elseif (round(h_h_l,decim) < round(h_h_ex,decim)) && (round(h_h_v,decim) > round(h_h_su,decim)) 
        H_h_vec = [h_h_ex  h_h_su]; % if two-phase only
    elseif (round(h_h_l,decim) < round(h_h_su,decim)) && (round(h_h_l,decim) > round(h_h_ex,decim))
        if (round(h_h_v,decim) < round(h_h_su,decim))
            H_h_vec = [h_h_ex  h_h_l  h_h_v  h_h_su]; % if liquid, two phase and vapour
        else
            H_h_vec = [h_h_ex  h_h_l  h_h_su]; % if liquid and two phase
        end
    elseif (round(h_h_v,decim) > round(h_h_ex,decim)) && (round(h_h_v,decim) < round(h_h_su,decim))
        if (round(h_h_l,decim) > round(h_h_ex,decim))
            H_h_vec = [h_h_ex  h_h_l  h_h_v  h_h_su]; % if liquid, two phase and vapour
        else
            H_h_vec = [h_h_ex  h_h_v  h_h_su]; % of twp phase and vapour
        end
    else
        H_h_vec = [h_h_ex  h_h_su]; %in all other cases (should never happen)
    end
    
    % Cell division for cold fluid (create a vector of enthalpy the different zones on the cold fluid side)
    if strcmp(param.port_c,'su')
        h_c_su = in_c;
        h_c_ex = h_c_su + Q_dot/m_dot_c;
    elseif strcmp(param.port_c,'ex')
        h_c_ex = in_c;
        h_c_su = h_c_ex - Q_dot/m_dot_c;
    end

    if not(isempty(strfind(fluid_c, 'INCOMP:')))
        h_c_l = h_c_ex*3;
        h_c_v = h_c_ex*3;
    else
        h_c_l = CoolProp.PropsSI('H','P',P_c,'Q',0, fluid_c);
        h_c_v = CoolProp.PropsSI('H','P',P_c,'Q',1, fluid_c);
    end
    if round(h_c_v,decim) < round(h_c_su,decim)
        H_c_vec = [h_c_su  h_c_ex]; % if vapour only
    elseif round(h_c_l,decim) > round(h_c_ex,decim)
        H_c_vec = [h_c_su  h_c_ex]; % if liquid only
    elseif (round(h_c_l,decim) < round(h_c_su,decim)) && (round(h_c_v,decim) > round(h_c_ex,decim))
        H_c_vec = [h_c_su  h_c_ex]; % if two-phase only
    elseif (round(h_c_l,decim) > round(h_c_su,decim)) && (round(h_c_l,decim) < round(h_c_ex,decim))
        if (round(h_c_v,decim) < round(h_c_ex,decim))
            H_c_vec = [h_c_su  h_c_l  h_c_v  h_c_ex]; % if liquid, two phase and vapour
        else
            H_c_vec = [h_c_su  h_c_l  h_c_ex]; % if liquid and two-phase
        end
    elseif (round(h_c_v,decim) > round(h_c_su,decim)) && (round(h_c_v,decim) < round(h_c_ex,decim))
        if (round(h_c_l,decim) > round(h_c_su,decim))
            H_c_vec = [h_c_su  h_c_l  h_c_v  h_c_ex]; % if liquid, two phase and vapour
        else
            H_c_vec = [h_c_su  h_c_v  h_c_ex]; %if two-phase and vapour
        end
    else
        H_c_vec = [h_c_su  h_c_ex]; %in all other cases (should never happen)
    end

    % Cell divitions for entire heat exchanger
    j = 1;
    while  j < max(length(H_h_vec),length(H_c_vec))-1
        Q_dot_h = m_dot_h*(H_h_vec(j+1)-H_h_vec(j));
        Q_dot_c = m_dot_c*(H_c_vec(j+1)-H_c_vec(j));

        if round(Q_dot_h,30) > round(Q_dot_c,30) 
            H_h_vec = [H_h_vec(1:j), H_h_vec(j)+Q_dot_c/m_dot_h, H_h_vec(j+1:end)];
        elseif round(Q_dot_h,30) < round(Q_dot_c,30) 
            H_c_vec = [H_c_vec(1:j), H_c_vec(j)+Q_dot_h/m_dot_c, H_c_vec(j+1:end)];
        end
        j = j+1;
    end 
    Q_dot_vec = m_dot_h*diff(H_h_vec);
    x = (H_h_vec-H_h_vec(1))./(H_h_vec(end)-H_h_vec(1));
    out.x_vec = x;
    out.Qdot_vec = Q_dot_vec;
    out.H_h_vec = H_h_vec;
    out.H_c_vec = H_c_vec;
    out.T_h_vec = NaN*ones(1,length(H_h_vec));
    out.T_c_vec = NaN*ones(1,length(H_c_vec));
    for k = 1:length(H_c_vec)
        out.T_h_vec(k) = CoolProp.PropsSI('T','P', P_h, 'H', H_h_vec(k), fluid_h);
        out.T_c_vec(k) = CoolProp.PropsSI('T','P', P_c, 'H', H_c_vec(k), fluid_c);        
    end
    out.DT_vec = out.T_h_vec-out.T_c_vec;
    out.pinch = min(out.T_h_vec-out.T_c_vec);
    

elseif strcmp(param.type_h,'T') && strcmp(param.type_c,'H') %% CASE 2 : HOT FLUID IS LIQUID (incompressible fluid) AND COLD FLUID MIGHT EXPERIENCE A PHASE CHANGE   
    if strcmp(param.port_c,'su')
        h_c_su = in_c;
        h_c_ex = h_c_su + Q_dot/m_dot_c;
    elseif strcmp(param.port_c,'ex')
        h_c_ex = in_c;
        h_c_su = h_c_ex - Q_dot/m_dot_c;
    end
    if not(isempty(strfind(fluid_c, 'INCOMP:')))
        h_c_l = h_c_ex*3;
        h_c_v = h_c_ex*3;
    else
        h_c_l = CoolProp.PropsSI('H','P',P_c,'Q',0, fluid_c);
        h_c_v = CoolProp.PropsSI('H','P',P_c,'Q',1, fluid_c);
    end
    
    if round(h_c_v,decim) < round(h_c_su,decim)
        H_c_vec = [h_c_su  h_c_ex];
    elseif round(h_c_l,decim) > round(h_c_ex,decim)
        H_c_vec = [h_c_su  h_c_ex];
    elseif (round(h_c_l,decim) < round(h_c_su,decim)) && (round(h_c_v,decim) > round(h_c_ex,decim))
        H_c_vec = [h_c_su  h_c_ex];
    elseif (round(h_c_l,decim) > round(h_c_su,decim)) && (round(h_c_l,decim) < round(h_c_ex,decim))
        if (round(h_c_v,decim) < round(h_c_ex,decim))
            H_c_vec = [h_c_su  h_c_l  h_c_v  h_c_ex];
        else
            H_c_vec = [h_c_su  h_c_l  h_c_ex];
        end
    elseif (round(h_c_v,decim) > round(h_c_su,decim)) && (round(h_c_v,decim) < round(h_c_ex,decim))
        if (round(h_c_l,decim) > round(h_c_su,decim))
            H_c_vec = [h_c_su  h_c_l  h_c_v  h_c_ex];
        else
            H_c_vec = [h_c_su  h_c_v  h_c_ex];
        end
    end
    
    % if hot fluid incompressible (T as input), only one cell of liquid phase
    if strcmp(param.port_h,'su')
        T_h_su = in_h;
        f_T_h_ex = @(x) Thex_def(x, T_h_su,  P_h, m_dot_h, Q_dot, fluid_h);
        lb =  T_h_su-Q_dot/m_dot_h/sf_PropsSI_bar('C', T_h_su, T_h_su, P_h, fluid_h)-30;
        ub = T_h_su;
        T_h_ex = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_h_ex );
    elseif strcmp(param.port_h,'ex')
        T_h_ex = in_h;      
        f_T_h_su = @(x) Tcex_def(x, T_h_ex,  P_h, m_dot_h, Q_dot, fluid_h);
        lb =  T_h_ex;
        ub = T_h_ex+Q_dot/m_dot_h/sf_PropsSI_bar('C', T_h_ex, T_h_ex, P_h, fluid_h)+30;
        T_h_su = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_h_su );
    end
    cp_h = sf_PropsSI_bar('C', T_h_su, T_h_ex, P_h, fluid_h);
    Q_dot_vec = NaN*ones(1,length(H_c_vec)-1);
    T_h_vec = NaN*ones(1,length(H_c_vec)-1);
    T_h_vec(1) = T_h_ex;
    
    % Cell divitions for entire heat exchanger
    j =1;
    while  j <length(H_c_vec)
        Q_dot_vec(j) = m_dot_c*(H_c_vec(j+1)-H_c_vec(j));
        T_h_vec(j+1) = T_h_vec(j) + Q_dot_vec(j)/m_dot_h/cp_h;
        j=j+1;
    end
    x = (H_c_vec-H_c_vec(1))./(H_c_vec(end)-H_c_vec(1));
    out.x_vec = x;
    out.Qdot_vec = Q_dot_vec;
    out.H_h_vec = NaN;
    out.H_c_vec = H_c_vec;
    out.T_h_vec = T_h_vec;
    out.T_c_vec = NaN*ones(1,length(H_c_vec));
    for k = 1:length(H_c_vec)
        out.T_c_vec(k) = CoolProp.PropsSI('T','P', P_c, 'H', H_c_vec(k), fluid_c);        
    end
    out.DT_vec = out.T_h_vec-out.T_c_vec;
    out.pinch = min(out.T_h_vec-out.T_c_vec);
    

elseif strcmp(param.type_h,'H') && strcmp(param.type_c,'T')  %% CASE 3 : HOT FLUID MIGHT EXPERIENCE A PHASE CHANGE  AND COLD FLUID IS LIQUID (incompressible fluid)
    if strcmp(param.port_h,'su')
        h_h_su = in_h;
        h_h_ex = h_h_su - Q_dot/m_dot_h;
    elseif strcmp(param.port_h,'ex')
        h_h_ex = in_h;
        h_h_su = h_h_ex + Q_dot/m_dot_h;
    end
    if not(isempty(strfind(fluid_h, 'INCOMP:')))
        h_h_l = h_h_su*3;
        h_h_v = h_h_su*3;
    else
        h_h_l = CoolProp.PropsSI('H','P',P_h,'Q',0, fluid_h);
        h_h_v = CoolProp.PropsSI('H','P',P_h,'Q',1, fluid_h);
    end 
    if round(h_h_v,decim) < round(h_h_ex,decim)
        H_h_vec = [h_h_ex  h_h_su];
    elseif round(h_h_l,decim) > round(h_h_su,decim)
        H_h_vec = [h_h_ex  h_h_su];
    elseif (round(h_h_l,decim) < round(h_h_ex,decim)) && (round(h_h_v,decim) > round(h_h_su,decim))
        H_h_vec = [h_h_ex  h_h_su];
    elseif (round(h_h_l,decim) < round(h_h_su,decim)) && (round(h_h_l,decim) > round(h_h_ex,decim))
        if (round(h_h_v,decim) < round(h_h_su,decim))
            H_h_vec = [h_h_ex  h_h_l  h_h_v  h_h_su];
        else
            H_h_vec = [h_h_ex  h_h_l  h_h_su];
        end
    elseif (round(h_h_v,decim) > round(h_h_ex,decim)) && (round(h_h_v,decim) < round(h_h_su,decim))
        if (round(h_h_l,decim) > round(h_h_ex,decim))
            H_h_vec = [h_h_ex  h_h_l  h_h_v  h_h_su];
        else
            H_h_vec = [h_h_ex  h_h_v  h_h_su];
        end
    end
    
    % if cold fluid incompressible (T as input), only one cell of liquid phase  
    if strcmp(param.port_c,'su')
        T_c_su = in_c;
        f_T_c_ex = @(x) Tcex_def(x, T_c_su,  P_c, m_dot_c, Q_dot, fluid_c);
        lb =  T_c_su;
        ub = T_c_su+Q_dot/m_dot_c/sf_PropsSI_bar('C', T_c_su, T_c_su, P_c, fluid_c)+30;
        T_c_ex = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_c_ex );
    elseif strcmp(param.port_c,'ex')
        T_c_ex = in_c;      
        f_T_c_su = @(x) Thex_def(x, T_c_ex,  P_c, m_dot_c, Q_dot, fluid_c);
        lb =  T_c_ex-Q_dot/m_dot_c/sf_PropsSI_bar('C', T_c_ex, T_c_ex, P_c, fluid_c)-30;
        ub = T_c_ex;
        T_c_su = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_c_su );
    end
    cp_c = sf_PropsSI_bar('C', T_c_su, T_c_ex, P_c, fluid_c);
    T_c_vec = [T_c_su T_c_ex];
    Q_dot_vec = NaN*ones(1,length(H_h_vec)-1);
    j = 1;
    while  j < length(H_h_vec)-1
        Q_dot_h = m_dot_h*(H_h_vec(j+1)-H_h_vec(j));
        T_c_vec = [T_c_vec(1:j), T_c_vec(j)+Q_dot_h/m_dot_c/cp_c, T_c_vec(j+1:end)];
        Q_dot_vec(j) = Q_dot_h;
        j = j+1;
    end
    x = (H_h_vec-H_h_vec(1))./(H_h_vec(end)-H_h_vec(1));
    out.x_vec = x;
    out.Qdot_vec = Q_dot_vec;
    out.H_h_vec = H_h_vec;
    out.H_c_vec = NaN;
    out.T_c_vec = T_c_vec;
    out.T_h_vec = NaN*ones(1,length(H_h_vec));
    for k = 1:length(H_h_vec)
        out.T_h_vec(k) = CoolProp.PropsSI('T','P', P_h, 'H', H_h_vec(k), fluid_h);        
    end
    out.DT_vec = out.T_h_vec-out.T_c_vec;
    out.pinch = min(out.T_h_vec-out.T_c_vec);
    
elseif strcmp(param.type_h,'T') && strcmp(param.type_c,'T')  
    % if cold fluid incompressible (T as input), only one cell of liquid phase  
    if strcmp(param.port_c,'su')
        T_c_su = in_c;
        f_T_c_ex = @(x) Tcex_def(x, T_c_su,  P_c, m_dot_c, Q_dot, fluid_c);
        lb =  T_c_su;
        ub = T_c_su+Q_dot/m_dot_c/sf_PropsSI_bar('C', T_c_su, T_c_su, P_c, fluid_c)+30;
        T_c_ex = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_c_ex );
    elseif strcmp(param.port_c,'ex')
        T_c_ex = in_c;      
        f_T_c_su = @(x) Thex_def(x, T_c_ex,  P_c, m_dot_c, Q_dot, fluid_c);
        lb =  T_c_ex-Q_dot/m_dot_c/sf_PropsSI_bar('C', T_c_ex, T_c_ex, P_c, fluid_c)-30;
        ub = T_c_ex;
        T_c_su = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_c_su );
    end
    out.T_c_vec = [T_c_su T_c_ex];
    out.H_c_vec = NaN;   
    
    % if hot fluid incompressible (T as input), only one cell of liquid phase 
    if strcmp(param.port_h,'su')
        T_h_su = in_h;
        f_T_h_ex = @(x) Thex_def(x, T_h_su,  P_h, m_dot_h, Q_dot, fluid_h);
        lb =  T_h_su-Q_dot/m_dot_h/sf_PropsSI_bar('C', T_h_su, T_h_su, P_h, fluid_h)-30;
        ub = T_h_su;
        T_h_ex = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_h_ex );
    elseif strcmp(param.port_h,'ex')
        T_h_ex = in_h;
        f_T_h_su = @(x) Tcex_def(x, T_h_ex,  P_h, m_dot_h, Q_dot, fluid_h);
        lb =  T_h_ex;
        ub = T_h_ex+Q_dot/m_dot_h/sf_PropsSI_bar('C', T_h_ex, T_h_ex, P_h, fluid_h)+30;
        T_h_su = zeroBrent ( lb, ub, 1e-6, 1e-6, f_T_h_su );
    end
    out.T_h_vec = [T_h_ex T_h_su]; 
    out.H_h_vec = NaN;
    out.Qdot_vec = Q_dot;
    out.x_vec = [0 1];
    out.DT_vec = out.T_h_vec-out.T_c_vec;
    out.pinch = min(out.T_h_vec-out.T_c_vec);
end
end

function err = Tcex_def(Tex, Tsu,  Psu, Mdot, Qdot, fluid)
err = Tex-(Tsu+Qdot/Mdot/sf_PropsSI_bar('C', Tsu, Tex, Psu, fluid));
end

function err = Thex_def(Tex, Tsu,  Psu, Mdot, Qdot, fluid)
err = Tex-(Tsu-Qdot/Mdot/sf_PropsSI_bar('C', Tsu, Tex, Psu, fluid));
end