function [Cost1,Cost2,Cost3,E,h,H,m_shs]=onestage_Cost1_unit_20231013(m_shs_ini,p_pv_unit,p_wt_unit)
%% 数据输入,算一阶段费用，风光出力由预测值给定

%电负荷
load('load_e.mat');
e=DataExport;
clear DataExport;
%天然气负荷
load('load_g.mat');
g=DataExport;
clear DataExport;
%热负荷
load('load_h.mat');
h=DataExport;
clear DataExport;
%氢负荷
load('load_H2.mat');
H2=DataExport;
clear DataExport;
%数据提取
[load_ex,load_ey]=get_data(e);
[load_gx,load_gy]=get_data(g);
[load_hx,load_hy]=get_data(h);
[load_H2x,load_H2y]=get_data(H2);
clear load_ex load_gx load_hx load_H2x
load_e=load_ey([1:24],1)';
load_g=load_gy([1:24],1)';
load_h=load_hy([1:24],1)';
load_H2_m=load_H2y([1:24],1)';
clear load_ey load_gy load_hy load_H2y e g h H2
%这里是对先择对应春季的负荷

%风电的每个时刻的单位出力
p_wt_unit=p_wt_unit;
%光伏的每个时刻的单位出力
p_pv_unit=p_pv_unit;
M=10e8;%表示大M法的辅助变量
%% 优化变量构建
epsilon_btin=sdpvar(1,24);%电池充放电标识
epsilon_btout=sdpvar(1,24);%
P_wt=sdpvar(1,24);%风电的计划功率出力
P_pv=sdpvar(1,24);%光伏的计划功率出力
P_grid=sdpvar(1,24);%电网计划购电功率
P_fc=sdpvar(1,24);%燃料电池计划功率出力
P_eb=sdpvar(1,24);%热电锅炉功率出力
P_elz=sdpvar(1,24);%电解槽产氢功率出力
%bt电池充放电功率
P_btin=sdpvar(1,24);
P_btout=sdpvar(1,24);
%季节性储氢设备进气出气质量
m_shsin=sdpvar(1,24);
m_shsout=sdpvar(1,24);
%天然气负荷质量
m_load_g=load_g/15.45;%这里15.45是天然气质量与功率的热值，从而得到负荷天然气需要的质量

C=[];
HHV_H=39.3;%141.8;
epsilon_elz=binvar(1,24);%电解槽
m_elz=(0.6*P_elz)/HHV_H;%产氢质量
P_elz_max=5000;
C=[C,
     0<=P_elz<=P_elz_max,
];

elz_on=binvar(1,24);%电解槽启动二进制变量
elz_off=binvar(1,24);%电解槽停止二进制变量
%电解槽启动和停止不能超过一定次数N_cycle
N_cycle=10;%这里是假设一天的启动停止次数不超过10
C=[C,
    0<=sum(elz_on+elz_off)<=N_cycle,
    elz_on+elz_off<=1,
    ];
for t=1:1:23
    C=[C,
       elz_on(1,t)-elz_off(1,t)==epsilon_elz(1,t+1)-epsilon_elz(1,t)
      ];   
end

m_fc=sdpvar(1,24);%表示典型日t时刻fc燃料电池的耗氢量
eta_fc_e=0.6;     %fc燃料电池的产电效率为0.6
eta_fc_h=0.2;      %fc燃料电池的产热效率为0.2
epsilon_fc=binvar(1,24);%fc燃料电池的状态变量

P_fc_e_max=10000;%燃料电池最大功率

%得到对应fc燃料电池的相关产电、产热功率
P_fc_e=eta_fc_e*m_fc*HHV_H;  %fc燃料电池的产电功率
P_fc_h=eta_fc_h*(1-eta_fc_e)*m_fc*HHV_H;%fc燃料电池的产热功率
%fc燃料电池功率约束
C=[C,0<=P_fc_e<=epsilon_fc.*P_fc_e_max,];
m_shs=sdpvar(1,24);
M_H=2.01588;%氢气的相对分子质量
V_shs_max=5;
V_shs=sdpvar(1,24);%产氢体积
p_shs_min=0.3*10e5;%季节性储氢设备的压强最小值
p_shs_max=3.0*10e5;%季节性储氢设备的压强最大值
%将两个变量乘积转换成线性结果
y=10;
delta=binvar(8,24);
D=y*(2^0*delta(1,:)+2^1*delta(2,:)+2^2*delta(3,:)+2^3*delta(4,:)+...
    2^4*delta(5,:)+2^5*delta(6,:)+2^6*delta(7,:)+2^7*delta(8,:));
C=[C,
    0<=D<=p_shs_max-p_shs_min,
    0<=V_shs<=V_shs_max,
   ];
tao=sdpvar(8,24);
T=y*(2^0*tao(1,:)+2^1*tao(2,:)+2^2*tao(3,:)+2^3*tao(4,:)+...
     2^4*tao(5,:)+2^5*tao(6,:)+2^6*tao(7,:)+2^7*tao(8,:));
C=[C,V_shs*p_shs_min+T==m_shs/M_H*8.314*293];

m_shs_max=(p_shs_max*V_shs_max*M_H)/(8.314*293);%季节性储氢设备最大存放质量,V为对应容量
C=[C,0<=m_shsin<=m_shs_max*0.1, %0.1为进气深度
     0<=m_shsout<=m_shs_max*0.1,%0.1为出气深度
     0<=m_shs<=m_shs_max, %在季节性储氢设备中能够存储的限制
   ];
%容量与进出气关系


%设备第一个时刻的设备质量存量
C=[C,m_shs(1,1)==m_shs_ini+m_shsin(1,1)*0.9-m_shsout(1,1)/0.9];
for i=2:1:24
    C=[C,
       m_shs(1,i)==m_shs(1,i-1)+m_shsin(1,i)*0.9-m_shsout(1,i)/0.9
          ];
end

m_inject=sdpvar(1,24);%在天然气管道加入的氢能质量
m_chpgas=sdpvar(1,24);%实际购买天然气的含量
omga_mix=0.1;%混氢比例从10%，14%到18%，这里选用10%
C=[C,omga_mix*(m_inject+m_chpgas)==m_inject];
HHV_NG=15.45;  %55.5j/kg,
HHV_mix=omga_mix*HHV_H+(1-omga_mix)*HHV_NG;
P_chp_e_max=2000;
%混合到天然气管道中的氢气对应的量应该是根据chp使用的量来决定
eta_chp_e=0.3;
eta_chp_h=0.5;
P_chp_e=eta_chp_e*HHV_mix*(m_chpgas+m_inject);
P_chp_h=eta_chp_h*HHV_mix*(m_chpgas+m_inject);
%燃气轮机功率限制
C=[C,0<=P_chp_e<=P_chp_e_max];

%光伏和风电设备容量
cap_wt=1;
cap_pv=1;
P_grid_max=5000;
P_eb_max=5000;
C=[C,
    0<=P_wt<=p_wt_unit,
    0<=P_pv<=p_pv_unit,
    0<=P_grid<=P_grid_max,
    0<=P_eb<=P_eb_max,
  ];

S_bt=sdpvar(1,24);%电池容量约束
P_btmax=500;
S_btmax=5000;
S_bt_ini=0;
C=[C, S_bt(1)==S_bt_ini+P_btin(1)*0.95-P_btout(1)/0.95,];
for t=2:24
    C=[C,
        S_bt(t)==S_bt(t-1)+P_btin(t)*0.95-P_btout(t)/0.95,
        ]; 
end
    C=[C,S_bt_ini==S_bt(24)];
    C=[C,
        S_bt_ini==S_bt(24),
        epsilon_btin+epsilon_btout<=1];
    C=[C,
        0<=P_btin<=P_btmax;
        0<=P_btout<=P_btmax;
        0<=S_bt<=S_btmax;
    ];

    C=[C,
       P_wt+P_pv+P_grid+P_fc_e+P_chp_e+P_btout==P_elz+P_eb+P_btin+load_e,
       P_chp_h+P_fc_h+P_eb==load_h,
       m_elz+m_shsout==m_shsin+load_H2_m+m_fc+m_inject,
      ];
%% cost1

m_buygas=m_load_g+m_chpgas;                                %购买天然气的量
P_buygas=m_buygas*15.45;                                   %对应天然气功率
gas_price=0.4;                                             %天然气价格
e_price=[0.36,0.36,0.36,0.36,0.36,0.36,0.36,...
         0.73,0.73,0.73,...
         1.08,1.08,1.08,1.08,1.08,...
         0.73,0.73,0.73,...
         1.08,1.08,1.08,1.08,...
         0.36,0.36]*2;       %阶梯电价
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cost1=(gas_price*sum(P_buygas)+e_price*P_grid')...
      /1.935101942689148e+05;
rel=((m_shs_ini/m_shs_max)+0.01)*5;
Cost2=rel*(m_shs_max-m_shs(1,24)+0.01)/m_shs_max;
Cost3=gas_price*sum(P_buygas)+e_price*P_grid';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ops=sdpsettings('solver','cplex','verbose',2,'usex0',0,'debug',1,'savesolveroutput',1,'savesolverinput',1);
ops.cplex.mip.tolerances.mipgap=0.1;
ops.cplex.exportmodel='Debug.lp';
%% 进行求解计算
% result=solvesdp(C,objective1,ops);
result=solvesdp(C,Cost1,ops);
if result.problem==0
    disp('求解成功')
else
    disp('求解过程中出错');
end
%% 数值显示

E=[P_wt',P_pv',P_grid',P_fc_e',P_chp_e',P_btout',-P_elz',-P_eb',-P_btin',-load_e'];
h=[P_chp_h',P_fc_h',P_eb',-load_h'];
H=[m_elz',m_shsout',-m_shsin',-load_H2_m',-m_fc',-m_inject'];
Cost1=value(Cost1);
Cost2=value(Cost2);
Cost3=value(Cost3);
m_shs=value(m_shs);
end