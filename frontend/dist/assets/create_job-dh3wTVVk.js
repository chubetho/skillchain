import{_ as b}from"./JobCard.vue_vue_type_script_setup_true_lang-zzqVhH63.js";import{d as g,r as m,m as V,o as v,b as y,e as s,f as e,w as d,g as i,u as a,i as x,n as w,j as $,p as h,q as B}from"./index-Pv3ZkBy6.js";import{_ as C}from"./Textarea.vue_vue_type_script_setup_true_lang-KOzQ60qK.js";import{_ as S,a as U}from"./Label.vue_vue_type_script_setup_true_lang-oXRrumf9.js";const j=["onSubmit"],N={class:"space-y-2"},k={class:"space-y-2"},M={class:"space-y-2"},P={class:"flex gap-3"},R={class:"w-[120px]"},T={class:"space-y-2"},q={class:"grow space-y-2"},D=g({__name:"create_job",setup(z){const t=m({title:"",description:"",badges:[],budget:0}),n=m("");V(n,()=>{t.value.badges=n.value.trim().split(" ")});function c(){console.log(t.value)}return(E,o)=>{const r=S,u=U,p=C,_=B,f=b;return v(),y("form",{class:"grid grid-cols-2 gap-10 py-10 items-center",onSubmit:h(c,["prevent"])},[s("div",N,[s("div",k,[e(r,{for:"title"},{default:d(()=>[i("title")]),_:1}),e(u,{id:"title",modelValue:a(t).title,"onUpdate:modelValue":o[0]||(o[0]=l=>a(t).title=l),type:"text"},null,8,["modelValue"])]),s("div",M,[e(r,{for:"description"},{default:d(()=>[i("description")]),_:1}),e(p,{id:"description",modelValue:a(t).description,"onUpdate:modelValue":o[1]||(o[1]=l=>a(t).description=l)},null,8,["modelValue"])]),s("div",P,[s("div",R,[s("div",T,[e(r,{for:"budget"},{default:d(()=>[i("budget")]),_:1}),e(u,{id:"budget",modelValue:a(t).budget,"onUpdate:modelValue":o[2]||(o[2]=l=>a(t).budget=l),modelModifiers:{number:!0},min:"0",step:"0.01",type:"number"},null,8,["modelValue"])])]),s("div",q,[e(r,{for:"badges"},{default:d(()=>[i("badges")]),_:1}),e(u,{id:"badges",modelValue:a(n),"onUpdate:modelValue":o[3]||(o[3]=l=>x(n)?n.value=l:null),type:"text"},null,8,["modelValue"])])]),e(_,{type:"submit"},{default:d(()=>[i(" Create ")]),_:1})]),s("div",null,[e(f,w($(a(t))),null,16)])],40,j)}}});export{D as default};
