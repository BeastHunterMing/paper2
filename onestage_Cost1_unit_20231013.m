function [Cost1,Cost2,Cost3,E,h,H,m_shs]=onestage_Cost1_unit_20231013(m_shs_ini,p_pv_unit,p_wt_unit)
%% ��������,��һ�׶η��ã���������Ԥ��ֵ����

%�縺��
load('load_e.mat');
e=DataExport;
clear DataExport;
%��Ȼ������
load('load_g.mat');
g=DataExport;
clear DataExport;
%�ȸ���
load('load_h.mat');
h=DataExport;
clear DataExport;
%�⸺��
load('load_H2.mat');
H2=DataExport;
clear DataExport;
%������ȡ
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
%�����Ƕ������Ӧ�����ĸ���

%����ÿ��ʱ�̵ĵ�λ����
p_wt_unit=p_wt_unit;
%�����ÿ��ʱ�̵ĵ�λ����
p_pv_unit=p_pv_unit;
M=10e8;%��ʾ��M���ĸ�������
%% �Ż���������
epsilon_btin=sdpvar(1,24);%��س�ŵ��ʶ
epsilon_btout=sdpvar(1,24);%
P_wt=sdpvar(1,24);%���ļƻ����ʳ���
P_pv=sdpvar(1,24);%����ļƻ����ʳ���
P_grid=sdpvar(1,24);%�����ƻ����繦��
P_fc=sdpvar(1,24);%ȼ�ϵ�ؼƻ����ʳ���
P_eb=sdpvar(1,24);%�ȵ��¯���ʳ���
P_elz=sdpvar(1,24);%���۲��⹦�ʳ���
%bt��س�ŵ繦��
P_btin=sdpvar(1,24);
P_btout=sdpvar(1,24);
%�����Դ����豸������������
m_shsin=sdpvar(1,24);
m_shsout=sdpvar(1,24);
%��Ȼ����������
m_load_g=load_g/15.45;%����15.45����Ȼ�������빦�ʵ���ֵ���Ӷ��õ�������Ȼ����Ҫ������

C=[];
HHV_H=39.3;%141.8;
epsilon_elz=binvar(1,24);%����
m_elz=(0.6*P_elz)/HHV_H;%��������
P_elz_max=5000;
C=[C,
     0<=P_elz<=P_elz_max,
];

elz_on=binvar(1,24);%�������������Ʊ���
elz_off=binvar(1,24);%����ֹͣ�����Ʊ���
%����������ֹͣ���ܳ���һ������N_cycle
N_cycle=10;%�����Ǽ���һ�������ֹͣ����������10
C=[C,
    0<=sum(elz_on+elz_off)<=N_cycle,
    elz_on+elz_off<=1,
    ];
for t=1:1:23
    C=[C,
       elz_on(1,t)-elz_off(1,t)==epsilon_elz(1,t+1)-epsilon_elz(1,t)
      ];   
end

m_fc=sdpvar(1,24);%��ʾ������tʱ��fcȼ�ϵ�صĺ�����
eta_fc_e=0.6;     %fcȼ�ϵ�صĲ���Ч��Ϊ0.6
eta_fc_h=0.2;      %fcȼ�ϵ�صĲ���Ч��Ϊ0.2
epsilon_fc=binvar(1,24);%fcȼ�ϵ�ص�״̬����

P_fc_e_max=10000;%ȼ�ϵ�������

%�õ���Ӧfcȼ�ϵ�ص���ز��硢���ȹ���
P_fc_e=eta_fc_e*m_fc*HHV_H;  %fcȼ�ϵ�صĲ��繦��
P_fc_h=eta_fc_h*(1-eta_fc_e)*m_fc*HHV_H;%fcȼ�ϵ�صĲ��ȹ���
%fcȼ�ϵ�ع���Լ��
C=[C,0<=P_fc_e<=epsilon_fc.*P_fc_e_max,];
m_shs=sdpvar(1,24);
M_H=2.01588;%��������Է�������
V_shs_max=5;
V_shs=sdpvar(1,24);%�������
p_shs_min=0.3*10e5;%�����Դ����豸��ѹǿ��Сֵ
p_shs_max=3.0*10e5;%�����Դ����豸��ѹǿ���ֵ
%�����������˻�ת�������Խ��
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

m_shs_max=(p_shs_max*V_shs_max*M_H)/(8.314*293);%�����Դ����豸���������,VΪ��Ӧ����
C=[C,0<=m_shsin<=m_shs_max*0.1, %0.1Ϊ�������
     0<=m_shsout<=m_shs_max*0.1,%0.1Ϊ�������
     0<=m_shs<=m_shs_max, %�ڼ����Դ����豸���ܹ��洢������
   ];
%�������������ϵ


%�豸��һ��ʱ�̵��豸��������
C=[C,m_shs(1,1)==m_shs_ini+m_shsin(1,1)*0.9-m_shsout(1,1)/0.9];
for i=2:1:24
    C=[C,
       m_shs(1,i)==m_shs(1,i-1)+m_shsin(1,i)*0.9-m_shsout(1,i)/0.9
          ];
end

m_inject=sdpvar(1,24);%����Ȼ���ܵ��������������
m_chpgas=sdpvar(1,24);%ʵ�ʹ�����Ȼ���ĺ���
omga_mix=0.1;%���������10%��14%��18%������ѡ��10%
C=[C,omga_mix*(m_inject+m_chpgas)==m_inject];
HHV_NG=15.45;  %55.5j/kg,
HHV_mix=omga_mix*HHV_H+(1-omga_mix)*HHV_NG;
P_chp_e_max=2000;
%��ϵ���Ȼ���ܵ��е�������Ӧ����Ӧ���Ǹ���chpʹ�õ���������
eta_chp_e=0.3;
eta_chp_h=0.5;
P_chp_e=eta_chp_e*HHV_mix*(m_chpgas+m_inject);
P_chp_h=eta_chp_h*HHV_mix*(m_chpgas+m_inject);
%ȼ���ֻ���������
C=[C,0<=P_chp_e<=P_chp_e_max];

%����ͷ���豸����
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

S_bt=sdpvar(1,24);%�������Լ��
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

m_buygas=m_load_g+m_chpgas;                                %������Ȼ������
P_buygas=m_buygas*15.45;                                   %��Ӧ��Ȼ������
gas_price=0.4;                                             %��Ȼ���۸�
e_price=[0.36,0.36,0.36,0.36,0.36,0.36,0.36,...
         0.73,0.73,0.73,...
         1.08,1.08,1.08,1.08,1.08,...
         0.73,0.73,0.73,...
         1.08,1.08,1.08,1.08,...
         0.36,0.36]*2;       %���ݵ��
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
%% ����������
% result=solvesdp(C,objective1,ops);
result=solvesdp(C,Cost1,ops);
if result.problem==0
    disp('���ɹ�')
else
    disp('�������г���');
end
%% ��ֵ��ʾ

E=[P_wt',P_pv',P_grid',P_fc_e',P_chp_e',P_btout',-P_elz',-P_eb',-P_btin',-load_e'];
h=[P_chp_h',P_fc_h',P_eb',-load_h'];
H=[m_elz',m_shsout',-m_shsin',-load_H2_m',-m_fc',-m_inject'];
Cost1=value(Cost1);
Cost2=value(Cost2);
Cost3=value(Cost3);
m_shs=value(m_shs);
end