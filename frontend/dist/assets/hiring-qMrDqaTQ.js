import{p as u,S as N,_ as R,a as q,b as O,c as P,d as j,e as z,f as F}from"./mocks-i9c2SUmc.js";import{_ as I}from"./ProfileCard.vue_vue_type_script_setup_true_lang-RvQ32Rtp.js";import{_ as T,a as U}from"./Label.vue_vue_type_script_setup_true_lang-oXRrumf9.js";import{d as A,r as d,c as D,a as E,o as r,b as i,e as t,f as e,w as a,u as _,i as m,F as p,t as G,g as J,h as f,j as H,n as K,k as M}from"./index-Pv3ZkBy6.js";const Q={class:"py-10 border-b"},W={class:"flex gap-2 items-center"},X={class:"w-10 h-10 border rounded-full flex-center shrink-0"},Y={class:"py-8 space-y-8"},Z={class:"flex justify-between items-center"},ee=t("div",null,[t("h1",{class:"text-4xl"}," profiles ")],-1),te={class:"flex items-center whitespace-nowrap gap-2"},se=t("span",{class:"text-muted-foreground"}," sort by: ",-1),oe={class:"min-w-[200px]"},ae={class:"grid grid-cols-3 gap-8"},ie=A({__name:"hiring",setup(ne){const n=d(""),l=d("lth"),h=[{label:"price: low to high",value:"lth"},{label:"price: hight to low",value:"htl"}],v=D(()=>(n.value?u.filter(s=>JSON.stringify(s).toLowerCase().includes(n.value.toLowerCase())):u).toSorted((s,c)=>l.value==="lth"?s.budget-c.budget:c.budget-s.budget));return(g,s)=>{const c=T,b=U,x=R,w=q,S=O,k=P,y=j,V=z,$=I,C=E("RouterLink"),L=F;return r(),i("div",null,[t("div",Q,[t("div",W,[e(c,{for:"q"},{default:a(()=>[t("div",X,[e(_(N),{size:20})])]),_:1}),e(b,{id:"q",modelValue:_(n),"onUpdate:modelValue":s[0]||(s[0]=o=>m(n)?n.value=o:null),placeholder:"search for profile or keyword"},null,8,["modelValue"])])]),t("div",Y,[t("div",Z,[ee,t("div",te,[se,t("div",oe,[e(V,{modelValue:_(l),"onUpdate:modelValue":s[1]||(s[1]=o=>m(l)?l.value=o:null)},{default:a(()=>[e(w,null,{default:a(()=>[e(x)]),_:1}),e(y,null,{default:a(()=>[e(k,null,{default:a(()=>[(r(),i(p,null,f(h,o=>e(S,{key:o.value,value:o.value},{default:a(()=>[J(G(o.label),1)]),_:2},1032,["value"])),64))]),_:1})]),_:1})]),_:1},8,["modelValue"])])])]),e(L,{class:"h-[500px]"},{default:a(()=>[t("div",ae,[(r(!0),i(p,null,f(_(v),(o,B)=>(r(),M(C,{key:B,class:"group",to:"/"},{default:a(()=>[e($,K(H(o)),null,16)]),_:2},1024))),128))])]),_:1})])])}}});export{ie as default};
